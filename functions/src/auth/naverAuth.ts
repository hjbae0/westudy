import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import axios from 'axios';

/**
 * 네이버 소셜 로그인 - Custom Token 발급
 *
 * 두 가지 모드를 지원한다:
 * 1. accessToken 모드: 클라이언트가 이미 access token을 가지고 있는 경우
 * 2. code 모드: authorization code를 보내면 서버에서 토큰 교환까지 처리
 *    (웹 CORS 이슈 방지를 위해 서버에서 토큰 교환)
 *
 * 네이버 API로 사용자 정보를 조회하고 Firebase Custom Token을 발급한다.
 * 신규 사용자인 경우 Firestore에 프로필을 자동 생성한다.
 */
export const naverCustomToken = functions
  .region('asia-northeast3')
  .https.onCall(async (data, context) => {
    const { accessToken: directAccessToken, code, state, redirectUri } = data as {
      accessToken?: string;
      code?: string;
      state?: string;
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
        const naverClientId = functions.config().naver?.client_id ?? '';
        const naverClientSecret = functions.config().naver?.client_secret ?? '';

        if (!naverClientId || !naverClientSecret) {
          throw new functions.https.HttpsError(
            'failed-precondition',
            '네이버 API 설정이 필요합니다. firebase functions:config:set naver.client_id=xxx naver.client_secret=xxx',
          );
        }

        const tokenResponse = await axios.get('https://nid.naver.com/oauth2.0/token', {
          params: {
            grant_type: 'authorization_code',
            client_id: naverClientId,
            client_secret: naverClientSecret,
            code,
            state: state || '',
            redirect_uri: redirectUri || '',
          },
        });

        if (tokenResponse.data.error) {
          throw new functions.https.HttpsError(
            'unauthenticated',
            `네이버 토큰 교환 실패: ${tokenResponse.data.error_description || tokenResponse.data.error}`,
          );
        }

        accessToken = tokenResponse.data.access_token;
      }

      if (!accessToken) {
        throw new functions.https.HttpsError(
          'internal',
          'access token을 획득하지 못했습니다.',
        );
      }

      // 1. 네이버 API로 사용자 정보 조회
      const naverResponse = await axios.get('https://openapi.naver.com/v1/nid/me', {
        headers: {
          Authorization: `Bearer ${accessToken}`,
        },
      });

      const naverResult = naverResponse.data;
      if (naverResult.resultcode !== '00') {
        throw new functions.https.HttpsError(
          'unauthenticated',
          `네이버 API 오류: ${naverResult.message}`,
        );
      }

      const naverUser = naverResult.response;
      const naverUserId = String(naverUser.id);
      const uid = `naver:${naverUserId}`;

      // 네이버 프로필 정보 추출
      const email = naverUser.email || '';
      const name = naverUser.name || naverUser.nickname || '';
      const profileImageUrl = naverUser.profile_image || null;
      const phone = naverUser.mobile ? naverUser.mobile.replace(/-/g, '') : null;

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
          phone,
          profileImageUrl,
          parentId: null,
          childrenIds: [],
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          provider: 'naver',
          naverId: naverUserId,
        });
        console.log(`[네이버 신규가입] uid=${uid}, name=${name}`);
      } else {
        // 기존 사용자 - 프로필 업데이트
        await db.collection('users').doc(uid).update({
          name,
          ...(profileImageUrl ? { profileImageUrl } : {}),
          ...(email ? { email } : {}),
          ...(phone ? { phone } : {}),
        });
      }

      // 4. Custom Token 발급
      const customToken = await authAdmin.createCustomToken(uid);

      console.log(`[네이버 로그인] uid=${uid}, name=${name}`);
      return { customToken };
    } catch (error: any) {
      console.error('[네이버 인증 오류]', error.message || error);

      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      if (axios.isAxiosError(error) && error.response?.status === 401) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          '유효하지 않은 네이버 access token입니다.',
        );
      }

      throw new functions.https.HttpsError(
        'internal',
        '네이버 인증 처리 중 오류가 발생했습니다.',
      );
    }
  });
