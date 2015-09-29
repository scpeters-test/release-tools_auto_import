package _configs_

import javaposse.jobdsl.dsl.Job

/*
  Implements:
     - bash: RTOOLS checkout
*/
class OSRFUNIXBase extends OSRFBase
{
  static void create(Job job)
  {
    job.with
    {
      steps
      {
        shell("""\
             #!/bin/bash -xe

             [[ -d ./scripts ]] &&  rm -fr ./scripts
             hg clone http://bitbucket.org/osrf/release-tools scripts -b \${RTOOLS_BRANCH}
             """.stripIndent())
      }
    }
  }
}
