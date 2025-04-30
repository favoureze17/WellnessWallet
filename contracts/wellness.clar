;; WellnessWallet Smart Contract
;; Handles pledges, vault distribution, and participant management

;; Error Constants
(define-constant ERR-UNAUTHORIZED-GUARDIAN-ACCESS (err u100))
(define-constant ERR-PARTICIPANT-DUPLICATE (err u101))
(define-constant ERR-PARTICIPANT-NONEXISTENT (err u102))
(define-constant ERR-VAULT-BALANCE-INSUFFICIENT (err u103))
(define-constant ERR-PLEDGE-MINIMUM-NOT-MET (err u104))
(define-constant ERR-CONTRACT-NOT-ACTIVE (err u105))
(define-constant ERR-PLEDGE-AMOUNT-INVALID (err u106))
(define-constant ERR-PARTICIPANT-STATUS-INVALID (err u107))
(define-constant ERR-GUARDIAN-ADDRESS-INVALID (err u108))

;; Data Variables
(define-data-var vault-guardian principal tx-sender)
(define-data-var vault-balance-total uint u0)
(define-data-var vault-active-status bool true)
(define-data-var pledge-minimum-amount uint u1000000) ;; 1 STX
(define-data-var vault-emergency-mode bool false)

;; Data Maps
(define-map participant-registry 
    principal 
    {
        is-participant-active: bool,
        wellness-funds-received: uint,
        last-allocation-block: uint,
        current-program-status: (string-ascii 20)
    }
)

(define-map supporter-registry
    principal
    {
        total-pledges-made: uint,
        last-pledge-block: uint
    }
)

;; Read-only functions
(define-read-only (get-vault-guardian)
    (var-get vault-guardian)
)

(define-read-only (get-vault-balance)
    (var-get vault-balance-total)
)

(define-read-only (get-participant-information (participant-wallet principal))
    (map-get? participant-registry participant-wallet)
)

(define-read-only (get-supporter-information (supporter-wallet principal))
    (map-get? supporter-registry supporter-wallet)
)

(define-read-only (check-vault-operational-status)
    (and (var-get vault-active-status) (not (var-get vault-emergency-mode)))
)

;; Private functions
(define-private (verify-guardian-privileges)
    (is-eq tx-sender (var-get vault-guardian))
)

(define-private (update-supporter-history (supporter-wallet principal) (pledge-value uint))
    (let (
        (existing-supporter-record (default-to 
            { total-pledges-made: u0, last-pledge-block: u0 } 
            (map-get? supporter-registry supporter-wallet)
        ))
    )
    (map-set supporter-registry
        supporter-wallet
        {
            total-pledges-made: (+ (get total-pledges-made existing-supporter-record) pledge-value),
            last-pledge-block: block-height
        }
    ))
)

;; Private validation functions
(define-private (validate-pledge-amount (amount uint))
    (and 
        (> amount u0)
        (<= amount u1000000000000) ;; Set reasonable upper limit
    )
)

(define-private (validate-participant-status (status-code (string-ascii 20)))
    (or 
        (is-eq status-code "active")
        (is-eq status-code "pending")
        (is-eq status-code "suspended")
        (is-eq status-code "completed")
    )
)

(define-private (validate-guardian-address (wallet-address principal))
    (and 
        (not (is-eq wallet-address (var-get vault-guardian)))
        (not (is-eq wallet-address (as-contract tx-sender)))
    )
)

;; Public functions
(define-public (make-pledge)
    (let (
        (pledge-value (stx-get-balance tx-sender))
    )
    (asserts! (>= pledge-value (var-get pledge-minimum-amount)) ERR-PLEDGE-MINIMUM-NOT-MET)
    (asserts! (check-vault-operational-status) ERR-CONTRACT-NOT-ACTIVE)
    
    (try! (stx-transfer? pledge-value tx-sender (as-contract tx-sender)))
    (var-set vault-balance-total (+ (var-get vault-balance-total) pledge-value))
    (update-supporter-history tx-sender pledge-value)
    (ok pledge-value))
)

(define-public (register-new-participant (participant-wallet principal))
    (begin
        (asserts! (verify-guardian-privileges) ERR-UNAUTHORIZED-GUARDIAN-ACCESS)
        (asserts! (is-none (map-get? participant-registry participant-wallet)) ERR-PARTICIPANT-DUPLICATE)
        
        (map-set participant-registry 
            participant-wallet
            {
                is-participant-active: true,
                wellness-funds-received: u0,
                last-allocation-block: u0,
                current-program-status: "active"
            }
        )
        (ok true)
    )
)

(define-public (allocate-funds (participant-wallet principal) (allocation-value uint))
    (begin
        (asserts! (verify-guardian-privileges) ERR-UNAUTHORIZED-GUARDIAN-ACCESS)
        (asserts! (check-vault-operational-status) ERR-CONTRACT-NOT-ACTIVE)
        (asserts! (>= (var-get vault-balance-total) allocation-value) ERR-VAULT-BALANCE-INSUFFICIENT)
        (asserts! 
            (is-some (map-get? participant-registry participant-wallet)) 
            ERR-PARTICIPANT-NONEXISTENT
        )
        
        (try! (as-contract (stx-transfer? allocation-value tx-sender participant-wallet)))
        (var-set vault-balance-total (- (var-get vault-balance-total) allocation-value))
        
        (let (
            (participant-record (unwrap! (map-get? participant-registry participant-wallet) ERR-PARTICIPANT-NONEXISTENT))
        )
        (map-set participant-registry
            participant-wallet
            {
                is-participant-active: (get is-participant-active participant-record),
                wellness-funds-received: (+ (get wellness-funds-received participant-record) allocation-value),
                last-allocation-block: block-height,
                current-program-status: (get current-program-status participant-record)
            }
        )
        (ok allocation-value))
    )
)

;; Administrative functions
(define-public (set-minimum-pledge (new-minimum-value uint))
    (begin
        (asserts! (verify-guardian-privileges) ERR-UNAUTHORIZED-GUARDIAN-ACCESS)
        (asserts! (validate-pledge-amount new-minimum-value) ERR-PLEDGE-AMOUNT-INVALID)
        (var-set pledge-minimum-amount new-minimum-value)
        (ok true)
    )
)

(define-public (toggle-vault-status)
    (begin
        (asserts! (verify-guardian-privileges) ERR-UNAUTHORIZED-GUARDIAN-ACCESS)
        (var-set vault-active-status (not (var-get vault-active-status)))
        (ok true)
    )
)

(define-public (enable-emergency-mode)
    (begin
        (asserts! (verify-guardian-privileges) ERR-UNAUTHORIZED-GUARDIAN-ACCESS)
        (var-set vault-emergency-mode true)
        (ok true)
    )
)

(define-public (disable-emergency-mode)
    (begin
        (asserts! (verify-guardian-privileges) ERR-UNAUTHORIZED-GUARDIAN-ACCESS)
        (var-set vault-emergency-mode false)
        (ok true)
    )
)

(define-public (update-participant-status (participant-wallet principal) (new-status (string-ascii 20)))
    (begin
        (asserts! (verify-guardian-privileges) ERR-UNAUTHORIZED-GUARDIAN-ACCESS)
        (asserts! (validate-participant-status new-status) ERR-PARTICIPANT-STATUS-INVALID)
        (asserts! 
            (is-some (map-get? participant-registry participant-wallet)) 
            ERR-PARTICIPANT-NONEXISTENT
        )
        
        (let (
            (current-record (unwrap! (map-get? participant-registry participant-wallet) ERR-PARTICIPANT-NONEXISTENT))
        )
        (map-set participant-registry
            participant-wallet
            {
                is-participant-active: (get is-participant-active current-record),
                wellness-funds-received: (get wellness-funds-received current-record),
                last-allocation-block: (get last-allocation-block current-record),
                current-program-status: new-status
            }
        )
        (ok true))
    )
)

;; Transfer ownership
(define-public (transfer-guardian-rights (new-guardian-address principal))
    (begin
        (asserts! (verify-guardian-privileges) ERR-UNAUTHORIZED-GUARDIAN-ACCESS)
        (asserts! (validate-guardian-address new-guardian-address) ERR-GUARDIAN-ADDRESS-INVALID)
        (var-set vault-guardian new-guardian-address)
        (ok true)
    )
)