package _configs_

import javaposse.jobdsl.dsl.Job

/*
  Implements:
    - priorioty 300
    - keep only 15 builds
*/
class OSRFLinuxInstall extends OSRFLinuxBase
{
  static void create(Job job)
  {
    OSRFLinuxBase.create(job)

    job.with
    {
      properties {
        priority 400
      }

      logRotator {
        numToKeep(15)
      }
    }
  }
}
