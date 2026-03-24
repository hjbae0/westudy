#!/bin/bash
SESSION="westudy"
tmux kill-session -t $SESSION 2>/dev/null
cd ~/westudy

tmux new-session -d -s $SESSION -n agents-1
tmux send-keys -t $SESSION:agents-1 "clear && echo '  A1: SCAFFOLD' && cd ~/westudy" Enter
tmux split-window -h -t $SESSION:agents-1
tmux send-keys "clear && echo '  A2: AUTH' && cd ~/westudy" Enter
tmux split-window -v -t $SESSION:agents-1.0
tmux send-keys "clear && echo '  A3: DB' && cd ~/westudy" Enter
tmux split-window -v -t $SESSION:agents-1.1
tmux send-keys "clear && echo '  A4: BOOKING' && cd ~/westudy" Enter

tmux new-window -t $SESSION -n agents-2
tmux send-keys -t $SESSION:agents-2 "clear && echo '  A5: UI-STUDENT' && cd ~/westudy" Enter
tmux split-window -h -t $SESSION:agents-2
tmux send-keys "clear && echo '  A6: UI-ADMIN' && cd ~/westudy" Enter
tmux split-window -v -t $SESSION:agents-2.0
tmux send-keys "clear && echo '  A7: NOTIFY' && cd ~/westudy" Enter
tmux split-window -v -t $SESSION:agents-2.1
tmux send-keys "clear && echo '  A8: TEST' && cd ~/westudy" Enter

tmux select-window -t $SESSION:agents-1
tmux attach -t $SESSION
