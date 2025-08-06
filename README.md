# Public Energy Management and Conservation Smart Contract System

A comprehensive blockchain-based system for managing energy consumption, conservation efforts, and renewable energy projects across government facilities.

## System Overview

This system consists of five interconnected smart contracts that work together to provide a complete energy management solution for public buildings:

### 1. Government Building Energy Monitoring Contract (`energy-monitoring.clar`)
- Tracks electricity, gas, and water usage across all government facilities
- Records monthly consumption data with timestamps
- Maintains historical usage patterns for analysis
- Provides baseline measurements for conservation efforts

### 2. Energy Efficiency Retrofit Coordination Contract (`retrofit-coordination.clar`)
- Manages upgrade projects for lighting, HVAC, and insulation systems
- Tracks project status, costs, and expected savings
- Coordinates contractor assignments and completion verification
- Maintains records of all efficiency improvements

### 3. Renewable Energy Project Management Contract (`renewable-projects.clar`)
- Coordinates solar panel and wind turbine installations
- Tracks project phases from planning to completion
- Manages energy generation capacity and actual output
- Records maintenance schedules and performance metrics

### 4. Utility Bill Processing and Payment Contract (`utility-billing.clar`)
- Processes energy bills for all government facilities
- Manages payment schedules and tracks outstanding balances
- Integrates with usage data for bill validation
- Provides cost analysis and budget tracking

### 5. Energy Conservation Incentive Contract (`conservation-incentives.clar`)
- Rewards departments that achieve energy reduction targets
- Calculates incentive payments based on conservation metrics
- Tracks department performance over time
- Manages incentive fund distribution

## Key Features

- **Transparent Tracking**: All energy data is recorded on-chain for public accountability
- **Automated Incentives**: Smart contracts automatically calculate and distribute conservation rewards
- **Comprehensive Monitoring**: Tracks all aspects of energy usage, from consumption to generation
- **Cost Management**: Integrated billing and payment processing with budget controls
- **Performance Analytics**: Historical data enables trend analysis and optimization

## Data Types

### Energy Usage
- Electricity consumption (kWh)
- Gas usage (therms)
- Water consumption (gallons)
- Monthly tracking with facility identification

### Project Management
- Retrofit projects with status tracking
- Renewable energy installations
- Cost estimates and actual expenditures
- Timeline management and completion verification

### Financial Management
- Utility bill processing and payments
- Conservation incentive calculations
- Budget allocation and tracking
- Cost-benefit analysis

## Security Features

- Role-based access control for different user types
- Input validation for all energy data
- Secure payment processing
- Audit trails for all transactions

## Getting Started

1. Deploy contracts in the following order:
    - energy-monitoring.clar
    - retrofit-coordination.clar
    - renewable-projects.clar
    - utility-billing.clar
    - conservation-incentives.clar

2. Initialize system with government facilities data
3. Set up monitoring schedules and conservation targets
4. Configure incentive parameters and reward structures
