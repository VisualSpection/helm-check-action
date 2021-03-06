#!/bin/bash -l

function printDelimeter {
  echo "----------------------------------------------------------------------"
}

function printLargeDelimeter {
  echo -e "\n\n------------------------------------------------------------------------------------------\n\n"
}

function printStepExecutionDelimeter {
  echo "----------------------------------------"
}

function displayInfo {
  echo
  printDelimeter
  echo
  HELM_CHECK_VERSION="v0.1.4"
  HELM_CHECK_SOURCES="https://github.com/igabaydulin/helm-check-action"
  echo "Helm-Check $HELM_CHECK_VERSION"
  echo -e "Source code: $HELM_CHECK_SOURCES"
  echo
  printDelimeter
}

function helmLint {
  echo -e "\n\n\n"
  echo -e "1. Checking charts for possible issues\n"
  printStepExecutionDelimeter
  cd $CHART_LOCATION

  for region in $REGIONS; do
    for env in $ENVS; do
      if [ -f $env/region/"${region}.yaml" ]; then
        echo "Evaluating Region:${region}, Environment:${env}..."
        echo "helm lint . -f ${env}/secrets.yaml -f ${env}/values.yaml -f ${env}/region/${region}.yaml"
        helm lint . -f $env/secrets.yaml -f $env/values.yaml -f $env/region/"${region}.yaml"
        HELM_LINT_EXIT_CODE=$?
        printStepExecutionDelimeter
        if [ $HELM_LINT_EXIT_CODE -eq 0 ]; then
          echo "Result: SUCCESS"
        else
          echo "Result: FAILED"
         return -1
        fi
      fi
    done
  done
  return $HELM_LINT_EXIT_CODE
}

function helmTemplate {
  printLargeDelimeter
  echo -e "2. Trying to render templates with provided values\n"
  if [[ "$1" -eq 0 ]]; then
    if [ -n "$CHART_VALUES" ]; then
      echo "helm template --values $CHART_VALUES $CHART_LOCATION"
      printStepExecutionDelimeter
      helm template --values "$CHART_VALUES" "$CHART_LOCATION"
      HELM_TEMPLATE_EXIT_CODE=$?
      printStepExecutionDelimeter
      if [ $HELM_TEMPLATE_EXIT_CODE -eq 0 ]; then
        echo "Result: SUCCESS"
      else
        echo "Result: FAILED"
      fi
      return $HELM_TEMPLATE_EXIT_CODE
    else
      printStepExecutionDelimeter
      echo "Skipped due to condition: \$CHART_VALUES is not provided"
      printStepExecutionDelimeter
    fi
  else
    echo "Skipped due to failure: Previous step has failed"
    return $1
  fi
  return 0
}

function totalInfo {
  printLargeDelimeter
  echo -e "3. Summary\n"
  if [[ "$1" -eq 0 ]]; then
    echo "Examination is completed; no errors found!"
    exit 0
  else
    echo "Examination is completed; errors found, check the log for details!"
    exit 1
  fi
}

CHART_LOCATION="chart"
ENVS="dev prod"

displayInfo
helmLint
totalInfo $?
