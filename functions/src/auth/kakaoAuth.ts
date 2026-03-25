import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import axios from 'axios';

/**
 * 카카오 소셜 로그인 - Custom Token 발급
 *
 * 두 가지 모드를 지원한다:
 * 1. accessToken 모드: 클라이언트가 이미 access token을 가지고 있는 경우
 * 2. code 모드: authorization code를 보내면 서버에서 토큰 교환까지 처리
 *    (웹 CORS 이슈 방지를 위해 서버에서 토큰 교환)
 *
 * 카카오 API로 사용자 정보를 조회하고 Firebase Custom Token을 발급한다.
 * 신규 사용자인 경우 Firestore에 프로필을 자동 생성한다.
 */
export const kakaoCustomToken = functions
  .region('asia-northeast3')
  .https.onCall(async (data, context) => {
    const { accessToken: directAccessToken, code, redirectUri } = data as {
      accessToken?: string;
      code?: string;
      redirectUri?: string;
    };

    if (!directAccessToken && !code) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'accessToken 또는 code가 필요합니다.',
      );
    }

    try {
      let accessToken = directAccessToken;

      // code가 있으면 서버에서 토큰 교환
      if (!accessToken && code) {
        const kakaoClientId = functions.config().kakao?.client_id ?? '';
        const kakaoClientSecret = functions.config().kakao?.client_secret ?? '';

        if (!kakaoClientId) {
          throw new functions.https.HttpsError(
            'failed-precondition',
            '카카오 API 설정이 필요합니다. firebase functions:config:set kakao.client_id=xxx',
          );
        }

        const tokenResponse = await axios.post(
          'https://kauth.kakao.com/oauth/token',
          new URLSearchParams({
            grant_type: 'authorization_code',
            client_id: kakaoClientId,
            redirect_uri: redirectUri || '',
            code,
            ...(kakaoClientSecret ? { client_secret: kakaoClientSecret } : {}),
          }).toString(),
          {
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded;charset=utf-8',
            },
          },
        );

        accessToken = tokenResponse.data.access_token;
      }

      if (!accessToken) {
        throw new functions.https.HttpsError(
          'internal',
          'access token을 획득하지 못했습니다.',
        );
      }

      // 1. 카카오 API로 사용자 정보 조회
      const kakaoResponse = await axios.get('https://kapi.kakao.com/v2/user/me', {
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/x-www-form-urlencoded;charset=utf-8',
        },
      });

      const kakaoUser = kakaoResponse.data;
      const kakaoUserId = String(kakaoUser.id);
      const uid = `kakao:${kakaoUserId}`;

      // 카카오 프로필 정보 추출
      const kakaoAccount = kakaoUser.kakao_account || {};
      const profile = kakaoAccount.profile || {};
      const email = kakaoAccount.email || '';
      const name = profile.nickname || '';
      const profileImageUrl = profile.profile_image_url || null;

      // 2. Firebase Auth 사용자 생성 또는 업데이트
      const authAdmin = admin.auth();
      try {
        await authAdmin.getUser(uid);
        // 기존 사용자 - 정보 업데이트
        await authAdmin.updateUser(uid, {
          displayName: name,
          ...(email ? { email } : {}),
          ...(profileImageUrl ? { photoURL: profileImageUrl } : {}),
        });
      } catch (error: any) {
        if (error.code === 'auth/user-not-found') {
          // 신규 사용자 생성
          await authAdmin.createUser({
            uid,
            displayName: name,
            ...(email ? { email } : {}),
            ...(profileImageUrl ? { photoURL: profileImageUrl } : {}),
          });
        } else {
          throw error;
        }
      }

      // 3. Firestore에 사용자 프로필 생성 (없는 경우)
      const db = admin.firestore();
      const userDoc = await db.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        await db.collection('users').doc(uid).set({
          name,
          email,
          role: 'student',
          phone: null,
          profileImageUrl,
          parentId: null,
          childrenIds: [],
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          provider: 'kakao',
          kakaoId: kakaoUserId,
        });
        console.log(`[카카오 신규가입] uid=${uid}, name=${name}`);
      } else {
        // 기존 사용자 - 프로필 이미지 등 업데이트
        await db.collection('users').doc(uid).update({
          name,
          ...(profileImageUrl ? { profileImageUrl } : {}),
          ...(email ? { email } : {}),
        });
      }

      // 4. Custom Token 발급
      const customToken = await authAdmin.createCustomToken(uid);

      console.log(`[카카오 로그인] uid=${uid}, name=${name}`);
      return { customToken };
    } catch (error: any) {
      console.error('[카카오 인증 오류]', error.message || error);

      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      if (axios.isAxiosError(error) && error.response?.status === 401) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          '유효하지 않은 카카오 access token입니다.',
        );
      }

      throw new functions.https.HttpsError(
        'internal',
        '카카오 인증 처리 중 오류가 발생했습니다.',
      );
    }
  });
