# namesilo-dyndns

This repo is 99% identical to https://github.com/windsting/update-namesilo-record/tree/master/shell_script. Due to the mechanism of k8s's cronjob and my only insteresed in shell script, I have to create this repo instead, but most credits should go to the original author, windsting.

Changes:
  - Add the "is cron job" logic
    - Will skip comparing IP if it is in a cron job
    - Will exit successfully if it is in a cron job
  - Only show last 4 chars of the API key to avoid exposing sensitive data
  - Add the "IS_DEBUG_MODE"
  - k8s friendly:
    - livenessProbe and readinessProbe friendly
    - pass API KEY as secret
    - helm friendly
      - Able to run as cron job or pod
      - resources limit and autocaling are already tuned, but allow users to override
