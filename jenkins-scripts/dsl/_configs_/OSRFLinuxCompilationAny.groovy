package _configs_

import javaposse.jobdsl.dsl.Job

/*
  -> OSRFLinuxCompilation
  -> GenericAnyJob

  Implements:
   - DEST_BRANCH parameter
*/
class OSRFLinuxCompilationAny
{
  static void create(Job job, String repo)
  {
    OSRFLinuxCompilation.create(job)

    /* Properties from generic any */
    GenericAnyJob.create(job, repo)

    job.with
    {
      steps
      {
        shell("""\
        #!/bin/bash -xe

        /bin/bash -xe ./scripts/jenkins-scripts/_bitbucket_create_build_status_file.bash
        /bin/bash -xe ./scripts/jenkins-scripts/_bitbucket_set_status.bash inprogress
        """.stripIndent())
      }

      parameters
      {
        stringParam('DEST_BRANCH','default2',
                    'Destination branch where the pull request will be merged.' +
                    'Mostly used to decide if calling to ABI checker')
      }

      publishers {
        postBuildScripts {
          steps {
            shell("""\
            #!/bin/bash -xe

            /bin/bash -xe ./scripts/jenkins-scripts/_bitbucket_set_status.bash ok')
            """.stripIndent())
          }
          onlyIfBuildSucceeds(true)
        }
      } // end of publishers

      configure { project ->
        project / publishers << 'hudson.plugins.postbuildtask.PostbuildTask' {
          tasks
          {
            "hudson.plugins.postbuildtask.TaskProperties"
            {
              logTexts {
                "hudson.plugins.postbuildtask.LogProperties" {
                  logText('marked build as failure')
                  operator('OR')
                }
                "hudson.plugins.postbuildtask.LogProperties" {
                  logText('Build was aborted')
                  operator('OR')
                }
                "hudson.plugins.postbuildtask.LogProperties" {
                              logText('result to UNSTABLE')
                  operator('OR')
                }
                "hudson.plugins.postbuildtask.LogProperties" {
                  logText('result is FAILURE')
                  operator('OR')
                 }
               }
            } // end of TaskProperties
            EscalateStatus(false)
            RunIfJobSuccessful(false)
            script('/bin/bash -xe ./scripts/jenkins-scripts/_bitbucket_set_status.bash failure')
          } // end of tasks
        } // end of project
      } // end of configure


    } // end of with
  } // end of create method
} // end of class
