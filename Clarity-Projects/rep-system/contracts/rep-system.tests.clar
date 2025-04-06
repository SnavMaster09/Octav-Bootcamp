(define-constant err-rate-failed (err u1000))
(define-constant err-test-failed (err u2000))

(define-public (test-first-rate (user-to-rate principal) (reputation-amount int))
  (let 
    (
      (user-to-rate-current-reputation (default-to 0 (get-user-reputation user-to-rate)))
      (last-rated-height (get-rated-height user-to-rate))
      (all-ratings (get ratings (default-to {ratings: (list)} (map-get? all-ratings-made tx-sender))))
    )
    (if (or (<= reputation-amount (if (>= (default-to 0 (get-user-reputation tx-sender)) 50) -20 -10))
                  (>= reputation-amount (if (>= (default-to 0 (get-user-reputation tx-sender)) 50) 20 10))
                  (<= (+ user-to-rate-current-reputation reputation-amount) -100) 
                  (>= (+ user-to-rate-current-reputation reputation-amount) 100)
                  (is-eq user-to-rate tx-sender)
                  (not (is-eq (len all-ratings) u0))
                  (and (is-some last-rated-height) 
                       (< stacks-block-height (+ (unwrap-panic last-rated-height) u1000))))
      (ok false)
      (begin
        (try! (rate-user user-to-rate reputation-amount))
        (let ((user-to-rate-updated-reputation (default-to 0 (get-user-reputation user-to-rate))))
          (if (not (is-eq user-to-rate-updated-reputation (+ user-to-rate-current-reputation reputation-amount)))
            (err (to-uint user-to-rate-updated-reputation))
            (ok true)
          )
        )
      )
    )
  )
)

(define-public (test-second-rate (user-to-rate principal) (reputation-amount int))
  (let 
    (
      (user-to-rate-current-reputation (default-to 0 (get-user-reputation user-to-rate)))
      (last-rated-height (get-rated-height user-to-rate))
      (all-ratings (get ratings (default-to {ratings: (list)} (map-get? all-ratings-made tx-sender))))
      (previous-amount (match (find-index user-to-rate)
        index (get amount (unwrap-panic (element-at? (get ratings (default-to {ratings: (list)} (map-get? user-ratings tx-sender))) index))) 0))
    )
    (if (or (<= reputation-amount (if (>= (default-to 0 (get-user-reputation tx-sender)) 50) -20 -10))
            (>= reputation-amount (if (>= (default-to 0 (get-user-reputation tx-sender)) 50) 20 10))
            (<= (+ user-to-rate-current-reputation reputation-amount) -100) 
            (>= (+ user-to-rate-current-reputation reputation-amount) 100)
            (is-eq user-to-rate tx-sender)
            (is-eq (len all-ratings) u0)
            (and (is-some last-rated-height) 
                 (< stacks-block-height (+ (unwrap-panic last-rated-height) u1000))))
      (ok false)
      (begin
        (try! (rate-user user-to-rate reputation-amount))
        (let ((user-to-rate-updated-reputation (default-to 0 (get-user-reputation user-to-rate))))
          (if (not (is-eq user-to-rate-updated-reputation (+ user-to-rate-current-reputation (- reputation-amount previous-amount))))
            (err (to-uint user-to-rate-updated-reputation))
            (ok true)
          )
        )
      )
    )
  )
)

(define-public (test-optional-decay-reputation (user principal))
  (let 
    (
      (initial-reputation (default-to 0 (get-user-reputation user)))
      (last-decay-time (default-to u0 (get last-decay (map-get? user-decay user))))
      (enough-time-passed (>= (- stacks-block-height last-decay-time) u1000))
      (after-initial-blocks (>= stacks-block-height u1000))
      (positive-rep (> initial-reputation 0))
      (should-decay (and enough-time-passed after-initial-blocks positive-rep))
      (expected-reputation (if should-decay
                              (- initial-reputation (/ initial-reputation 10))
                              initial-reputation))
      (decay-result (unwrap-panic (optional-decay-reputation user)))
      (new-reputation (default-to 0 (get-user-reputation user)))
    )
    (asserts! (is-eq new-reputation expected-reputation) err-test-failed)
    
    (ok true)
  )
)
