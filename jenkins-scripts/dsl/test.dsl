import _configs_.*
import javaposse.jobdsl.dsl.Job

def ignition_ci_job = job("_test_job_from_dsl")
OSRFLinuxBase.create(ignition_ci_job)
