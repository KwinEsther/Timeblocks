;; Constants
(define-constant TOKEN_SUPPLY u1000000) ;; Maximum supply of reward tokens
(define-constant BASE_REWARD_AMOUNT u10) ;; Base tokens awarded per completed session
(define-constant STREAK_BONUS u2) ;; Additional bonus for maintaining a streak
(define-constant MAX_STREAK u7) ;; Maximum streak days for bonus calculation
(define-constant ERR_INVALID_SESSION u1) ;; Error code for invalid session
(define-constant ERR_NO_REWARDS u2) ;; Error code for no rewards to claim
(define-constant ERR_SUPPLY_EXCEEDED u3) ;; Error code for token supply exceeded

;; Data Variables
(define-data-var total-tokens-minted uint u0)
(define-data-var total-sessions uint u0)
(define-data-var contract-owner principal tx-sender)

;; Data Maps
(define-map user-sessions principal uint)
(define-map user-rewards principal uint)
(define-map user-session-start principal uint)
(define-map user-streak principal uint)
(define-map user-last-session principal uint)

;; Public Functions

(define-public (start-session (duration uint))
  (let
    (
      (caller tx-sender)
      (current-block (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (asserts! (> duration u0) (err ERR_INVALID_SESSION))
    (map-set user-session-start caller current-block)
    (ok true)
  )
)

(define-public (complete-session (duration uint))
  (let
    (
      (caller tx-sender)
      (start-time (default-to u0 (map-get? user-session-start caller)))
      (current-block (unwrap-panic (get-block-info? time (- block-height u1))))
      (actual-duration (- current-block start-time))
      (last-session-day (default-to u0 (map-get? user-last-session caller)))
      (current-day (/ current-block u86400))
      (streak (default-to u0 (map-get? user-streak caller)))
      (reward-amount (+ BASE_REWARD_AMOUNT (* (min streak MAX_STREAK) STREAK_BONUS)))
    )
    (asserts! (and (> start-time u0) (>= actual-duration duration)) (err ERR_INVALID_SESSION))
    (map-set user-sessions caller (+ (default-to u0 (map-get? user-sessions caller)) u1))
    (map-set user-rewards caller (+ (default-to u0 (map-get? user-rewards caller)) reward-amount))
    (if (is-eq last-session-day (- current-day u1))
      (map-set user-streak caller (+ streak u1))
      (map-set user-streak caller u1)
    )
    (map-set user-last-session caller current-day)
    (var-set total-sessions (+ (var-get total-sessions) u1))
    (var-set total-tokens-minted (+ (var-get total-tokens-minted) reward-amount))
    (asserts! (<= (var-get total-tokens-minted) TOKEN_SUPPLY) (err ERR_SUPPLY_EXCEEDED))
    (ok reward-amount)
  )
)

(define-public (claim-rewards)
  (let
    (
      (caller tx-sender)
      (reward-balance (default-to u0 (map-get? user-rewards caller)))
    )
    (asserts! (> reward-balance u0) (err ERR_NO_REWARDS))
    (map-set user-rewards caller u0)
    (ok reward-balance)
  )
)

;; Read-Only Functions

(define-read-only (get-session-count (user principal))
  (default-to u0 (map-get? user-sessions user))
)

(define-read-only (get-reward-balance (user principal))
  (default-to u0 (map-get? user-rewards user))
)

(define-read-only (get-user-streak (user principal))
  (default-to u0 (map-get? user-streak user))
)

(define-read-only (get-global-stats)
  {
    total-sessions: (var-get total-sessions),
    total-tokens-minted: (var-get total-tokens-minted)
  }
)

;; Private Functions

(define-private (is-contract-owner)
  (is-eq tx-sender (var-get contract-owner))
)