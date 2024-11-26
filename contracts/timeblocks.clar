;; Constants
(define-constant TOKEN_SUPPLY u1000000) ;; Maximum supply of reward tokens
(define-constant REWARD_AMOUNT u10) ;; Tokens awarded per completed session

;; Data Variables
(define-data-var total-tokens-minted uint u0) ;; Tracks the total tokens minted
(define-data-var total-sessions uint u0) ;; Tracks the total sessions completed
(define-data-var contract-owner principal tx-sender) ;; Contract owner

;; Data Maps
(define-map user-sessions principal uint) ;; Tracks completed sessions per user
(define-map user-rewards principal uint) ;; Tracks reward tokens per user
(define-map user-session-start-time principal uint) ;; Tracks the start time of the current session per user (using session count)
(define-map user-session-duration principal uint) ;; Tracks session durations for each user

;; Public Functions

;; Start a Pomodoro session (simulate start time with session counter)
(define-public (start-session)
  (let
    (
      (caller tx-sender) ;; Current user
      (current-session (default-to u0 (map-get? user-sessions caller))) ;; Get current session number
    )
    (begin
      ;; "Simulate" session start by incrementing session count
      (map-set user-sessions caller (+ current-session u1))
      
      ;; Log session start (for user tracking)
      (ok { message: "Pomodoro session started. Stay focused!" })
    )
  )
)

;; Complete a session, calculate the duration (using session count), and reward tokens
(define-public (complete-session)
  (let
    (
      (caller tx-sender) ;; Current user
      (current-sessions (default-to u0 (map-get? user-sessions caller))) ;; User's completed sessions
      (current-rewards (default-to u0 (map-get? user-rewards caller))) ;; User's current reward balance
      (start-time (default-to u0 (map-get? user-session-start-time caller))) ;; Get the start time of the session
      (end-time current-sessions) ;; Use the current session number as the "end time"
      (session-duration (- end-time start-time)) ;; Calculate session duration (simulated)
    )
    (begin
      ;; Store the session duration for the user
      (map-set user-session-duration caller session-duration)
      
      ;; Update user data
      (map-set user-rewards caller (+ current-rewards REWARD_AMOUNT))

      ;; Increment global metrics
      (var-set total-sessions (+ (var-get total-sessions) u1))
      (var-set total-tokens-minted (+ (var-get total-tokens-minted) REWARD_AMOUNT))

      ;; Check token supply limits
      (if (> (var-get total-tokens-minted) TOKEN_SUPPLY)
        (err u1000) ;; Error: Maximum token supply reached
        (ok { message: "Session completed, duration recorded, and rewards issued!" })
      )
    )
  )
)

;; Claim accumulated rewards
(define-public (claim-rewards)
  (let
    (
      (caller tx-sender) ;; Current user
      (reward-balance (default-to u0 (map-get? user-rewards caller))) ;; User's reward balance
    )
    (begin
      (if (is-eq reward-balance u0)
        (err u4000) ;; Error: No rewards to claim
        (begin
          ;; Reset rewards to zero after claiming
          (map-set user-rewards caller u0)
          (ok { claimed: reward-balance, message: "Rewards successfully claimed!" })
        )
      )
    )
  )
)

;; Read-Only Functions

;; Get total completed sessions for a user
(define-read-only (get-session-count (user principal))
  (default-to u0 (map-get? user-sessions user))
)

;; Get reward balance for a user
(define-read-only (get-reward-balance (user principal))
  (default-to u0 (map-get? user-rewards user))
)

;; Get the duration of the most recent session for a user
(define-read-only (get-session-duration (user principal))
  (default-to u0 (map-get? user-session-duration user))
)

;; Get global stats: total sessions and minted tokens
(define-read-only (get-global-stats)
  {
    total-sessions: (var-get total-sessions),
    total-tokens-minted: (var-get total-tokens-minted)
  }
)

;; Private Functions

;; Ensure only the contract owner can perform certain actions
(define-private (only-owner)
  (if (is-eq tx-sender (var-get contract-owner))
    true ;; If the sender is the owner, return true
    false ;; Otherwise, return false
  )
)
