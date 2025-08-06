;; Renewable Energy Project Management Contract
;; Coordinates solar panel and wind turbine installations

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u300))
(define-constant ERR-INVALID-PROJECT (err u301))
(define-constant ERR-INVALID-CAPACITY (err u302))
(define-constant ERR-INVALID-PHASE (err u303))
(define-constant ERR-PROJECT-EXISTS (err u304))

;; Project Types
(define-constant TYPE-SOLAR u1)
(define-constant TYPE-WIND u2)
(define-constant TYPE-GEOTHERMAL u3)
(define-constant TYPE-HYDRO u4)

;; Project Phases
(define-constant PHASE-PLANNING u1)
(define-constant PHASE-PERMITTING u2)
(define-constant PHASE-CONSTRUCTION u3)
(define-constant PHASE-TESTING u4)
(define-constant PHASE-OPERATIONAL u5)
(define-constant PHASE-MAINTENANCE u6)

;; Data Variables
(define-data-var next-project-id uint u1)

;; Data Maps
(define-map renewable-projects
  { project-id: uint }
  {
    facility-id: uint,
    project-type: uint,
    name: (string-ascii 100),
    description: (string-ascii 500),
    capacity-kw: uint,
    estimated-cost: uint,
    actual-cost: uint,
    current-phase: uint,
    start-date: uint,
    expected-completion: uint,
    actual-completion: (optional uint),
    contractor: (optional principal),
    created-by: principal
  }
)

(define-map energy-generation
  { project-id: uint, month: uint, year: uint }
  {
    generated-kwh: uint,
    capacity-factor: uint,
    maintenance-hours: uint,
    recorded-by: principal,
    timestamp: uint
  }
)

(define-map maintenance-schedules
  { project-id: uint, maintenance-id: uint }
  {
    maintenance-type: (string-ascii 100),
    scheduled-date: uint,
    completed-date: (optional uint),
    cost: uint,
    technician: (optional principal),
    notes: (string-ascii 300)
  }
)

(define-map project-performance
  { project-id: uint }
  {
    total-generation: uint,
    average-capacity-factor: uint,
    total-maintenance-cost: uint,
    uptime-percentage: uint,
    last-updated: uint
  }
)

;; Authorization check
(define-private (is-authorized (user principal))
  (or (is-eq user CONTRACT-OWNER)
      (is-eq user tx-sender)))

;; Create renewable energy project
(define-public (create-renewable-project (facility-id uint)
                                       (project-type uint)
                                       (name (string-ascii 100))
                                       (description (string-ascii 500))
                                       (capacity-kw uint)
                                       (estimated-cost uint)
                                       (expected-completion uint))
  (let ((project-id (var-get next-project-id)))
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (and (>= project-type TYPE-SOLAR) (<= project-type TYPE-HYDRO)) ERR-INVALID-PROJECT)
    (asserts! (> capacity-kw u0) ERR-INVALID-CAPACITY)
    (asserts! (> estimated-cost u0) ERR-INVALID-CAPACITY)

    (map-set renewable-projects
      { project-id: project-id }
      {
        facility-id: facility-id,
        project-type: project-type,
        name: name,
        description: description,
        capacity-kw: capacity-kw,
        estimated-cost: estimated-cost,
        actual-cost: u0,
        current-phase: PHASE-PLANNING,
        start-date: block-height,
        expected-completion: expected-completion,
        actual-completion: none,
        contractor: none,
        created-by: tx-sender
      }
    )

    ;; Initialize performance tracking
    (map-set project-performance
      { project-id: project-id }
      {
        total-generation: u0,
        average-capacity-factor: u0,
        total-maintenance-cost: u0,
        uptime-percentage: u100,
        last-updated: block-height
      }
    )

    (var-set next-project-id (+ project-id u1))
    (ok project-id)))

;; Update project phase
(define-public (update-phase (project-id uint) (new-phase uint))
  (let ((project (unwrap! (map-get? renewable-projects { project-id: project-id }) ERR-INVALID-PROJECT)))
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (and (>= new-phase PHASE-PLANNING) (<= new-phase PHASE-MAINTENANCE)) ERR-INVALID-PHASE)
    (asserts! (> new-phase (get current-phase project)) ERR-INVALID-PHASE)

    (let ((updated-project (merge project { current-phase: new-phase })))
      ;; If moving to operational phase, set completion date
      (if (is-eq new-phase PHASE-OPERATIONAL)
        (map-set renewable-projects
          { project-id: project-id }
          (merge updated-project { actual-completion: (some block-height) }))
        (map-set renewable-projects
          { project-id: project-id }
          updated-project))
    )
    (ok true)))

;; Record energy generation
(define-public (record-generation (project-id uint)
                                (month uint)
                                (year uint)
                                (generated-kwh uint)
                                (capacity-factor uint)
                                (maintenance-hours uint))
  (begin
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-some (map-get? renewable-projects { project-id: project-id })) ERR-INVALID-PROJECT)
    (asserts! (and (>= month u1) (<= month u12)) ERR-INVALID-CAPACITY)
    (asserts! (>= year u2020) ERR-INVALID-CAPACITY)
    (asserts! (<= capacity-factor u100) ERR-INVALID-CAPACITY)

    (map-set energy-generation
      { project-id: project-id, month: month, year: year }
      {
        generated-kwh: generated-kwh,
        capacity-factor: capacity-factor,
        maintenance-hours: maintenance-hours,
        recorded-by: tx-sender,
        timestamp: block-height
      }
    )

    ;; Update performance metrics
    (let ((performance (unwrap! (map-get? project-performance { project-id: project-id }) ERR-INVALID-PROJECT)))
      (map-set project-performance
        { project-id: project-id }
        (merge performance {
          total-generation: (+ (get total-generation performance) generated-kwh),
          last-updated: block-height
        })
      )
    )

    (ok true)))

;; Schedule maintenance
(define-public (schedule-maintenance (project-id uint)
                                   (maintenance-id uint)
                                   (maintenance-type (string-ascii 100))
                                   (scheduled-date uint)
                                   (estimated-cost uint))
  (begin
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-some (map-get? renewable-projects { project-id: project-id })) ERR-INVALID-PROJECT)
    (asserts! (> estimated-cost u0) ERR-INVALID-CAPACITY)

    (map-set maintenance-schedules
      { project-id: project-id, maintenance-id: maintenance-id }
      {
        maintenance-type: maintenance-type,
        scheduled-date: scheduled-date,
        completed-date: none,
        cost: estimated-cost,
        technician: none,
        notes: ""
      }
    )
    (ok true)))

;; Complete maintenance
(define-public (complete-maintenance (project-id uint)
                                   (maintenance-id uint)
                                   (actual-cost uint)
                                   (technician principal)
                                   (notes (string-ascii 300)))
  (let ((maintenance (unwrap! (map-get? maintenance-schedules { project-id: project-id, maintenance-id: maintenance-id }) ERR-INVALID-PROJECT)))
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-none (get completed-date maintenance)) ERR-INVALID-PHASE)
    (asserts! (> actual-cost u0) ERR-INVALID-CAPACITY)

    ;; Update maintenance record
    (map-set maintenance-schedules
      { project-id: project-id, maintenance-id: maintenance-id }
      (merge maintenance {
        completed-date: (some block-height),
        cost: actual-cost,
        technician: (some technician),
        notes: notes
      })
    )

    ;; Update performance metrics
    (let ((performance (unwrap! (map-get? project-performance { project-id: project-id }) ERR-INVALID-PROJECT)))
      (map-set project-performance
        { project-id: project-id }
        (merge performance {
          total-maintenance-cost: (+ (get total-maintenance-cost performance) actual-cost),
          last-updated: block-height
        })
      )
    )

    (ok true)))

;; Read-only functions
(define-read-only (get-project (project-id uint))
  (map-get? renewable-projects { project-id: project-id }))

(define-read-only (get-generation (project-id uint) (month uint) (year uint))
  (map-get? energy-generation { project-id: project-id, month: month, year: year }))

(define-read-only (get-maintenance (project-id uint) (maintenance-id uint))
  (map-get? maintenance-schedules { project-id: project-id, maintenance-id: maintenance-id }))

(define-read-only (get-performance (project-id uint))
  (map-get? project-performance { project-id: project-id }))

(define-read-only (get-total-projects)
  (- (var-get next-project-id) u1))

;; Calculate project efficiency
(define-read-only (calculate-efficiency (project-id uint))
  (let ((project (map-get? renewable-projects { project-id: project-id }))
        (performance (map-get? project-performance { project-id: project-id })))
    (match project
      project-data
      (match performance
        performance-data
        (if (and (> (get capacity-kw project-data) u0) (> (get total-generation performance-data) u0))
          (some (/ (get total-generation performance-data) (get capacity-kw project-data)))
          none)
        none)
      none)))
