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


   /*
    * args input map contains:
    *    String build_status,
    *    String build_desc = "",
    *    String build_name = 'ENV.JOB_NAME',
    *    String build_url  = 'ENV.BUILD_URL'
    */
   static String script_code_set_code(Map args)
   {
      // default values for some arguments
      if (! args.containsKey('build_desc'))
         args.build_desc = ''

      if (! args.containsKey('build_name'))
         args.build_name = 'ENV.JOB_NAME'

      if (! args.containsKey('build_url'))
         args.build_url = 'ENV.BUILD_URL'

     return """\

        stage 'set bitbucket status: ${args.build_status}'
         node("lightweight-linux")
         {
             build job: "_bitbucket-set_status",
               propagate: false, wait: true,
                  parameters:
                    [[\$class: 'StringParameterValue', name: 'RTOOLS_BRANCH',          value: "\$RTOOLS_BRANCH"],
                     [\$class: 'StringParameterValue', name: 'JENKINS_BUILD_REPO',     value: "\$SRC_REPO"],
                     [\$class: 'StringParameterValue', name: 'JENKINS_BUILD_HG_HASH',  value: env.MERCURIAL_REVISION_SHORT],
                     [\$class: 'StringParameterValue', name: 'JENKINS_BUILD_JOB_NAME', value: "${args.build_name}"],
                     [\$class: 'StringParameterValue', name: 'JENKINS_BUILD_URL',      value: "${args.build_url}"],
                     [\$class: 'StringParameterValue', name: 'JENKINS_BUILD_DESC',     value: "${args.build_desc}"],
                     [\$class: 'StringParameterValue', name: 'BITBUCKET_STATUS',       value: "${args.build_status}"]]
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
