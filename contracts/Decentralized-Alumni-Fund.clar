(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_ALREADY_REGISTERED (err u101))
(define-constant ERR_NOT_REGISTERED (err u102))
(define-constant ERR_INSUFFICIENT_FUNDS (err u103))
(define-constant ERR_REQUEST_NOT_FOUND (err u104))
(define-constant ERR_REQUEST_ALREADY_PROCESSED (err u105))
(define-constant ERR_INVALID_AMOUNT (err u106))
(define-constant ERR_SELF_FUNDING (err u107))
(define-constant ERR_REPAYMENT_NOT_DUE (err u108))

(define-fungible-token gratitude-token)

(define-data-var next-request-id uint u1)
(define-data-var total-fund-balance uint u0)
(define-data-var min-contribution uint u100)
(define-data-var repayment-period uint u52560)
(define-data-var interest-rate uint u200)
(define-data-var last-interest-block uint u0)
(define-data-var compound-frequency uint u2016)

(define-map alumni
  { alumni-address: principal }
  {
    total-contributed: uint,
    reputation-score: uint,
    join-block: uint,
    active: bool
  }
)

(define-map students
  { student-address: principal }
  {
    total-received: uint,
    total-repaid: uint,
    reputation-score: uint,
    join-block: uint,
    active: bool
  }
)

(define-map funding-requests
  { request-id: uint }
  {
    student: principal,
    amount: uint,
    purpose: (string-ascii 256),
    created-block: uint,
    status: (string-ascii 10),
    approvals: uint,
    rejections: uint,
    funded-amount: uint,
    due-block: uint
  }
)

(define-map request-votes
  { request-id: uint, voter: principal }
  { vote: (string-ascii 10), block-height: uint }
)

(define-map alumni-contributions
  { alumni-address: principal, request-id: uint }
  { amount: uint, block-height: uint }
)

(define-map repayment-schedule
  { student: principal, request-id: uint }
  {
    original-amount: uint,
    repaid-amount: uint,
    due-block: uint,
    status: (string-ascii 10)
  }
)

(define-read-only (get-alumni-info (alumni-address principal))
  (map-get? alumni { alumni-address: alumni-address })
)

(define-read-only (get-student-info (student-address principal))
  (map-get? students { student-address: student-address })
)

(define-read-only (get-funding-request (request-id uint))
  (map-get? funding-requests { request-id: request-id })
)

(define-read-only (get-total-fund-balance)
  (var-get total-fund-balance)
)

(define-read-only (get-next-request-id)
  (var-get next-request-id)
)

(define-read-only (get-gratitude-balance (address principal))
  (ft-get-balance gratitude-token address)
)

(define-read-only (get-vote (request-id uint) (voter principal))
  (map-get? request-votes { request-id: request-id, voter: voter })
)

(define-read-only (get-repayment-info (student principal) (request-id uint))
  (map-get? repayment-schedule { student: student, request-id: request-id })
)

(define-read-only (get-interest-rate)
  (var-get interest-rate)
)

(define-read-only (get-compound-frequency)
  (var-get compound-frequency)
)

(define-read-only (calculate-accrued-interest)
  (let ((current-balance (var-get total-fund-balance))
        (last-block (var-get last-interest-block))
        (current-block stacks-block-height)
        (compound-freq (var-get compound-frequency))
        (rate (var-get interest-rate)))
    (if (and (> current-balance u0) (>= (- current-block last-block) compound-freq))
      (let ((periods (/ (- current-block last-block) compound-freq))
            (interest-per-period (/ (* current-balance rate) u10000)))
        (* periods interest-per-period)
      )
      u0
    )
  )
)

(define-public (register-alumni)
  (let ((alumni-address tx-sender))
    (if (is-some (get-alumni-info alumni-address))
      ERR_ALREADY_REGISTERED
      (begin
        (map-set alumni 
          { alumni-address: alumni-address }
          {
            total-contributed: u0,
            reputation-score: u100,
            join-block: stacks-block-height,
            active: true
          }
        )
        (ok true)
      )
    )
  )
)

(define-public (register-student)
  (let ((student-address tx-sender))
    (if (is-some (get-student-info student-address))
      ERR_ALREADY_REGISTERED
      (begin
        (map-set students 
          { student-address: student-address }
          {
            total-received: u0,
            total-repaid: u0,
            reputation-score: u100,
            join-block: stacks-block-height,
            active: true
          }
        )
        (ok true)
      )
    )
  )
)

(define-public (contribute-to-fund (amount uint))
  (let ((alumni-address tx-sender))
    (if (and (> amount u0) (is-some (get-alumni-info alumni-address)))
      (match (stx-transfer? amount tx-sender (as-contract tx-sender))
        success (begin
          (let ((current-info (unwrap-panic (get-alumni-info alumni-address))))
            (map-set alumni 
              { alumni-address: alumni-address }
              (merge current-info { 
                total-contributed: (+ (get total-contributed current-info) amount),
                reputation-score: (+ (get reputation-score current-info) (/ amount u10))
              })
            )
            (var-set total-fund-balance (+ (var-get total-fund-balance) amount))
            (try! (ft-mint? gratitude-token (/ amount u10) alumni-address))
            (ok true)
          )
        )
        error ERR_INSUFFICIENT_FUNDS
      )
      ERR_NOT_REGISTERED
    )
  )
)

(define-public (create-funding-request (amount uint) (purpose (string-ascii 256)))
  (let ((student tx-sender) (request-id (var-get next-request-id)))
    (if (and (> amount u0) (is-some (get-student-info student)))
      (begin
        (map-set funding-requests 
          { request-id: request-id }
          {
            student: student,
            amount: amount,
            purpose: purpose,
            created-block: stacks-block-height,
            status: "pending",
            approvals: u0,
            rejections: u0,
            funded-amount: u0,
            due-block: (+ stacks-block-height (var-get repayment-period))
          }
        )
        (var-set next-request-id (+ request-id u1))
        (ok request-id)
      )
      ERR_NOT_REGISTERED
    )
  )
)

(define-public (vote-on-request (request-id uint) (vote-type (string-ascii 10)))
  (let ((voter tx-sender))
    (if (is-some (get-alumni-info voter))
      (match (get-funding-request request-id)
        request-info (if (is-eq (get status request-info) "pending")
          (begin
            (map-set request-votes 
              { request-id: request-id, voter: voter }
              { vote: vote-type, block-height: stacks-block-height }
            )
            (let ((updated-approvals (if (is-eq vote-type "approve") 
                                       (+ (get approvals request-info) u1) 
                                       (get approvals request-info)))
                  (updated-rejections (if (is-eq vote-type "reject") 
                                        (+ (get rejections request-info) u1) 
                                        (get rejections request-info))))
              (map-set funding-requests 
                { request-id: request-id }
                (merge request-info { 
                  approvals: updated-approvals,
                  rejections: updated-rejections
                })
              )
              (ok true)
            )
          )
          ERR_REQUEST_ALREADY_PROCESSED
        )
        ERR_REQUEST_NOT_FOUND
      )
      ERR_NOT_AUTHORIZED
    )
  )
)

(define-public (fund-approved-request (request-id uint))
  (match (get-funding-request request-id)
    request-info (if (and (>= (get approvals request-info) u3)
                         (is-eq (get status request-info) "pending")
                         (>= (var-get total-fund-balance) (get amount request-info)))
      (begin
        (try! (as-contract (stx-transfer? (get amount request-info) tx-sender (get student request-info))))
        (var-set total-fund-balance (- (var-get total-fund-balance) (get amount request-info)))
        (let ((student-info (unwrap-panic (get-student-info (get student request-info)))))
          (map-set students 
            { student-address: (get student request-info) }
            (merge student-info { 
              total-received: (+ (get total-received student-info) (get amount request-info))
            })
          )
        )
        (map-set funding-requests 
          { request-id: request-id }
          (merge request-info { 
            status: "funded",
            funded-amount: (get amount request-info)
          })
        )
        (map-set repayment-schedule 
          { student: (get student request-info), request-id: request-id }
          {
            original-amount: (get amount request-info),
            repaid-amount: u0,
            due-block: (get due-block request-info),
            status: "active"
          }
        )
        (ok true)
      )
      ERR_INSUFFICIENT_FUNDS
    )
    ERR_REQUEST_NOT_FOUND
  )
)

(define-public (repay-funding (request-id uint) (amount uint))
  (let ((student tx-sender))
    (match (get-repayment-info student request-id)
      repayment-info (if (and (> amount u0) 
                             (is-eq (get status repayment-info) "active")
                             (<= amount (- (get original-amount repayment-info) (get repaid-amount repayment-info))))
        (match (stx-transfer? amount student (as-contract tx-sender))
          success (begin
            (var-set total-fund-balance (+ (var-get total-fund-balance) amount))
            (let ((new-repaid (+ (get repaid-amount repayment-info) amount))
                  (student-info (unwrap-panic (get-student-info student))))
              (map-set repayment-schedule 
                { student: student, request-id: request-id }
                (merge repayment-info { 
                  repaid-amount: new-repaid,
                  status: (if (>= new-repaid (get original-amount repayment-info)) "completed" "active")
                })
              )
              (map-set students 
                { student-address: student }
                (merge student-info { 
                  total-repaid: (+ (get total-repaid student-info) amount),
                  reputation-score: (+ (get reputation-score student-info) (/ amount u5))
                })
              )
              (try! (ft-mint? gratitude-token (/ amount u5) student))
              (ok true)
            )
          )
          error ERR_INSUFFICIENT_FUNDS
        )
        ERR_INVALID_AMOUNT
      )
      ERR_REQUEST_NOT_FOUND
    )
  )
)

(define-public (send-gratitude (recipient principal) (amount uint) (message (string-ascii 140)))
  (if (> amount u0)
    (match (ft-transfer? gratitude-token amount tx-sender recipient)
      success (ok true)
      error (err error)
    )
    ERR_INVALID_AMOUNT
  )
)

(define-public (compound-interest)
  (let ((accrued-interest (calculate-accrued-interest)))
    (if (> accrued-interest u0)
      (begin
        (var-set total-fund-balance (+ (var-get total-fund-balance) accrued-interest))
        (var-set last-interest-block stacks-block-height)
        (ok accrued-interest)
      )
      (ok u0)
    )
  )
)

(define-public (update-interest-rate (new-rate uint))
  (if (is-eq tx-sender CONTRACT_OWNER)
    (begin
      (var-set interest-rate new-rate)
      (ok true)
    )
    ERR_NOT_AUTHORIZED
  )
)

(define-public (update-compound-frequency (new-frequency uint))
  (if (is-eq tx-sender CONTRACT_OWNER)
    (begin
      (var-set compound-frequency new-frequency)
      (ok true)
    )
    ERR_NOT_AUTHORIZED
  )
)

(define-public (update-min-contribution (new-amount uint))
  (if (is-eq tx-sender CONTRACT_OWNER)
    (begin
      (var-set min-contribution new-amount)
      (ok true)
    )
    ERR_NOT_AUTHORIZED
  )
)

(define-public (emergency-pause)
  (if (is-eq tx-sender CONTRACT_OWNER)
    (ok true)
    ERR_NOT_AUTHORIZED
  )
)
