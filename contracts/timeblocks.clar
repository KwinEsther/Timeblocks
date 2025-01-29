;; Constants
(define-constant TOKEN_SUPPLY u1000000)
(define-constant BASE_REWARD_AMOUNT u10)
(define-constant STREAK_BONUS u2)
(define-constant MAX_STREAK u7)
(define-constant ERR_INVALID_SESSION u1)
(define-constant ERR_NO_REWARDS u2)
(define-constant ERR_SUPPLY_EXCEEDED u3)
(define-constant BLOCKS_PER_DAY u144)
(define-constant STAKE_MULTIPLIER u2)
(define-constant MIN_STAKE_DURATION u288)
(define-constant EARLY_UNSTAKE_PENALTY u10)

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
(define-map user-stakes principal uint)
(define-map user-stake-start-block principal uint)

;; Public Functions

(define-public (start-session (duration uint))
  (let
    (
      (caller tx-sender)
    )
    (asserts! (> duration u0) (err ERR_INVALID_SESSION))
    (map-set user-session-start caller burn-block-height)
    (ok true)
  )
)

(define-public (complete-session (duration uint))
  (let
    (
      (caller tx-sender)
      (start-block (default-to u0 (map-get? user-session-start caller)))
      (blocks-passed (- burn-block-height start-block))
      (last-session-block (default-to u0 (map-get? user-last-session caller)))
      (streak (default-to u0 (map-get? user-streak caller)))
      (capped-streak (if (<= streak MAX_STREAK) streak MAX_STREAK))
      (reward-amount (+ BASE_REWARD_AMOUNT (* capped-streak STREAK_BONUS)))
    )
    (asserts! (and (> start-block u0) (>= blocks-passed duration)) (err ERR_INVALID_SESSION))
    (map-set user-sessions caller (+ (default-to u0 (map-get? user-sessions caller)) u1))
    (map-set user-rewards caller (+ (default-to u0 (map-get? user-rewards caller)) reward-amount))
    (if (< (- burn-block-height last-session-block) BLOCKS_PER_DAY)
      (map-set user-streak caller (+ streak u1))
      (map-set user-streak caller u1)
    )
    (map-set user-last-session caller burn-block-height)
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

;; New Staking Features

(define-public (stake-tokens (amount uint))
  (let
    (
      (caller tx-sender)
    )
    (asserts! (> amount u0) (err ERR_INVALID_SESSION))
    (asserts! (>= (var-get total-tokens-minted) amount) (err ERR_SUPPLY_EXCEEDED))
    (map-set user-stakes caller amount)
    (map-set user-stake-start-block caller burn-block-height)
    (var-set total-tokens-minted (- (var-get total-tokens-minted) amount))
    (ok amount)
  )
)

(define-public (unstake-tokens)
  (let
    (
      (caller tx-sender)
      (stake-data (default-to u0 (map-get? user-stakes caller)))
      (stake-start-block (default-to u0 (map-get? user-stake-start-block caller)))
      (blocks-staked (- burn-block-height stake-start-block))
      (penalty (if (< blocks-staked MIN_STAKE_DURATION) (/ (* stake-data EARLY_UNSTAKE_PENALTY) u100) u0))
      (final-amount (- stake-data penalty))
    )
    (asserts! (> stake-data u0) (err ERR_NO_REWARDS))
    (map-set user-stakes caller u0)
    (map-set user-stake-start-block caller u0)
    (var-set total-tokens-minted (+ (var-get total-tokens-minted) final-amount))
    (ok final-amount)
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
