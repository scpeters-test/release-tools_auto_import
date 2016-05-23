package _configs_

import javaposse.jobdsl.dsl.Job

/*
  Implements:
     - label
*/

class OSRFCIWorkFlow
{
   static String script_code_init_hook()
   {
     return """\
       currentBuild.description =  "\$JOB_DESCRIPTION"
       def publish_result  = ""
       def compilation_job = null

       stage 'checkout for the mercurial hash'
       node("lightweight-linux") {
         checkout([\$class: 'MercurialSCM', credentialsId: '', installation: '(Default)',
                   revision: "\$SRC_BRANCH", source: "\$SRC_REPO",
                   propagate: false, wait: true])
          sh 'echo `hg id -i` > SCM_hash'
          env.MERCURIAL_REVISION_SHORT = readFile('SCM_hash').trim()
       }
     """
   }

   static String script_code_end_hook()
   {
     return """\
       currentBuild.result = publish_result
     """
   }

   static String script_code_set_code(String status)
   {
     return """\

        stage 'set bitbucket status: ${status}'
         node("lightweight-linux")
         {
             build job: _bitbucket-set_status
               propagate: false, wait: true,
                  parameters:
                    [[\$class: 'StringParameterValue', name: 'RTOOLS_BRANCH',          value: "\$RTOOLS_BRANCH"],
                     [\$class: 'StringParameterValue', name: 'JENKINS_BUILD_REPO',     value: "\$SRC_REPO"],
                     [\$class: 'StringParameterValue', name: 'JENKINS_BUILD_HG_HASH',  value: env.MERCURIAL_REVISION_SHORT],
                     [\$class: 'StringParameterValue', name: 'JENKINS_BUILD_JOB_NAME', value: env.JOB_NAME],
                     [\$class: 'StringParameterValue', name: 'JENKINS_BUILD_URL',      value: env.BUILD_URL],
                     [\$class: 'StringParameterValue', name: 'BITBUCKET_STATUS',       value: "${status}"]]
         }
     """
   }

   static void create(Job job)
   {

      job.with
      {
        label "lightweight-linux"
      } // end of job
   } // end of create
}
