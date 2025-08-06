;; Government Building Energy Monitoring Contract
;; Tracks electricity, gas, and water usage in public facilities

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-FACILITY (err u101))
(define-constant ERR-INVALID-USAGE (err u102))
(define-constant ERR-FACILITY-EXISTS (err u103))

;; Data Variables
(define-data-var next-facility-id uint u1)

;; Data Maps
(define-map facilities
  { facility-id: uint }
  {
    name: (string-ascii 100),
    address: (string-ascii 200),
    facility-type: (string-ascii 50),
    square-footage: uint,
    active: bool
  }
)

(define-map energy-usage
  { facility-id: uint, month: uint, year: uint }
  {
    electricity-kwh: uint,
    gas-therms: uint,
    water-gallons: uint,
    recorded-by: principal,
    timestamp: uint
  }
)

(define-map facility-baselines
  { facility-id: uint }
  {
    baseline-electricity: uint,
    baseline-gas: uint,
    baseline-water: uint,
    baseline-year: uint
  }
)

;; Authorization check
(define-private (is-authorized (user principal))
  (or (is-eq user CONTRACT-OWNER)
      (is-eq user tx-sender)))

;; Register a new government facility
(define-public (register-facility (name (string-ascii 100))
                                 (address (string-ascii 200))
                                 (facility-type (string-ascii 50))
                                 (square-footage uint))
  (let ((facility-id (var-get next-facility-id)))
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> square-footage u0) ERR-INVALID-USAGE)
    (asserts! (is-none (map-get? facilities { facility-id: facility-id })) ERR-FACILITY-EXISTS)

    (map-set facilities
      { facility-id: facility-id }
      {
        name: name,
        address: address,
        facility-type: facility-type,
        square-footage: square-footage,
        active: true
      }
    )

    (var-set next-facility-id (+ facility-id u1))
    (ok facility-id)))

;; Record monthly energy usage
(define-public (record-usage (facility-id uint)
                           (month uint)
                           (year uint)
                           (electricity-kwh uint)
                           (gas-therms uint)
                           (water-gallons uint))
  (begin
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-some (map-get? facilities { facility-id: facility-id })) ERR-INVALID-FACILITY)
    (asserts! (and (>= month u1) (<= month u12)) ERR-INVALID-USAGE)
    (asserts! (>= year u2020) ERR-INVALID-USAGE)

    (map-set energy-usage
      { facility-id: facility-id, month: month, year: year }
      {
        electricity-kwh: electricity-kwh,
        gas-therms: gas-therms,
        water-gallons: water-gallons,
        recorded-by: tx-sender,
        timestamp: block-height
      }
    )
    (ok true)))

;; Set baseline usage for a facility
(define-public (set-baseline (facility-id uint)
                           (baseline-electricity uint)
                           (baseline-gas uint)
                           (baseline-water uint)
                           (baseline-year uint))
  (begin
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-some (map-get? facilities { facility-id: facility-id })) ERR-INVALID-FACILITY)
    (asserts! (>= baseline-year u2020) ERR-INVALID-USAGE)

    (map-set facility-baselines
      { facility-id: facility-id }
      {
        baseline-electricity: baseline-electricity,
        baseline-gas: baseline-gas,
        baseline-water: baseline-water,
        baseline-year: baseline-year
      }
    )
    (ok true)))

;; Get facility information
(define-read-only (get-facility (facility-id uint))
  (map-get? facilities { facility-id: facility-id }))

;; Get energy usage for a specific month
(define-read-only (get-usage (facility-id uint) (month uint) (year uint))
  (map-get? energy-usage { facility-id: facility-id, month: month, year: year }))

;; Get facility baseline
(define-read-only (get-baseline (facility-id uint))
  (map-get? facility-baselines { facility-id: facility-id }))

;; Calculate usage variance from baseline
(define-read-only (calculate-variance (facility-id uint) (month uint) (year uint))
  (let ((usage (map-get? energy-usage { facility-id: facility-id, month: month, year: year }))
        (baseline (map-get? facility-baselines { facility-id: facility-id })))
    (match usage
      usage-data
      (match baseline
        baseline-data
        (some {
          electricity-variance: (if (>= (get electricity-kwh usage-data) (get baseline-electricity baseline-data))
                                  (- (get electricity-kwh usage-data) (get baseline-electricity baseline-data))
                                  (- (get baseline-electricity baseline-data) (get electricity-kwh usage-data))),
          gas-variance: (if (>= (get gas-therms usage-data) (get baseline-gas baseline-data))
                          (- (get gas-therms usage-data) (get baseline-gas baseline-data))
                          (- (get baseline-gas baseline-data) (get gas-therms usage-data))),
          water-variance: (if (>= (get water-gallons usage-data) (get baseline-water baseline-data))
                            (- (get water-gallons usage-data) (get baseline-water baseline-data))
                            (- (get baseline-water baseline-data) (get water-gallons usage-data)))
        })
        none)
      none)))

;; Get total facilities count
(define-read-only (get-total-facilities)
  (- (var-get next-facility-id) u1))
