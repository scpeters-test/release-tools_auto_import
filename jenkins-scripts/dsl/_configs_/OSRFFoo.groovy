package _configs_

import javaposse.jobdsl.dsl.Job

/*
  -> GenericMail

  Implements:
     - description
     - RTOOLS parame + groovy to set jobDescription
     - base mail for Failures and Unstables
*/

class OSRFFoo
{
   static void create(Job job, String build_any_job_name)
   {
     GenericMail.include_mail(job)

     job.with
     {
     	description 'Automatic generated job by DSL jenkins. Please do not edit manually'

        parameters {
          stringParam('RTOOLS_BRANCH','default','release-tool branch to use')
          booleanParam('NO_MAILS',false,'do not send any notification by mail')
        }

        steps
        {
           systemGroovyCommand("build.setDescription('RTOOLS_BRANCH: ' + build.buildVariableResolver.resolve('RTOOLS_BRANCH'));")
        }
      }
    }
}
