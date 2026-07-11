# Deployment Matrix

This document maps all Git clones of repositories on the production server to check for Deployment Drift.

| Repository Location | Remote URL | Branch | Commit SHA | Active Container | Project Name |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `/home/dev/actions-runner/kaos/_work/K.A.O.S/K.A.O.S` | `https://github.com/Brian5m1th/K.A.O.S` | `main` | `452fc57e9f75f256e48a39b28ac155378c175e09` | **YES** | `kaos-platform` |
| `/home/dev/docker/deploy-guide/deploy-guide` | `https://github.com/.../deploy-guide` (implied) | Unknown | Unknown | **NO** | `deploy-guide` |
| `/home/dev/docker/calendar/fall/fall-calendar-2024` | Unknown | Unknown | Unknown | **NO** | `fall-calendar` |

## Deployment Drift Check
* **Expected Commit**: `452fc57e9f75f256e48a39b28ac155378c175e09` (Active main branch commit)
* **Running Commit**: `452fc57e9f75f256e48a39b28ac155378c175e09` (Calculated from docker image tag `sha-452fc57` and container environment `COMMIT_SHA=452fc57`)
* **Drift Status**: **NO DRIFT** (The active container is running the correct image corresponding to the latest deployment commit).
