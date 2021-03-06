package _configs_

import javaposse.jobdsl.dsl.Job

/*
  -> OSRFBase

  Implements:
     - bash: RTOOLS checkout
*/
class OSRFUNIXBase extends OSRFBase
{
  static void create(Job job)
  {
    OSRFBase.create(job)

    job.with
    {
      steps
      {
        shell("""\
             #!/bin/bash -xe

             [[ -d ./scripts ]] &&  rm -fr ./scripts
             # Hack for homebrew on Mac OS X since mercurial can be uninstalled
             # during homebrew bottle builds
             which hg || brew install hg
             hg clone https://bitbucket.org/osrf/release-tools scripts -b \${RTOOLS_BRANCH}
             """.stripIndent())
      }
    }
  }
}
