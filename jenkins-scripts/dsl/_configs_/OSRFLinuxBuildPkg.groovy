package _configs_

import javaposse.jobdsl.dsl.Job

/*
  -> OSRFLinuxBase
  -> GenericRemoteToken

  Implements:
    - priority 100
    - keep only 10 last artifacts
    - parameters:
        - PACKAGE
        - VERSION
        - RELEASE_VERSION
        - DISTRO
        - ARCH
        - SOURCE_TARBALL_URI
        - RELEASE_REPO_BRANCH
        - PACKAGE_ALIAS 
        - UPLOAD_TO_REPO
    - publish artifacts
    - launch repository_ng
*/
class OSRFLinuxBuildPkg extends OSRFLinuxBase

{  
  static void create(Job job)
  {
    OSRFLinuxBase.create(job)
    GenericRemoteToken.create(job)

    job.with
    {
      properties {
        priority 100
      }

      logRotator {
        artifactNumToKeep(10)
      }

      parameters {
        stringParam("PACKAGE",null,"Package name to be built")
        stringParam("VERSION",null,"Packages version to be built")
        stringParam("RELEASE_VERSION", null, "Packages release version")
        stringParam("DISTRO", null, "Ubuntu distribution to build packages for")
        stringParam("ARCH", null, "Architecture to build packages for")
        stringParam("SOURCE_TARBALL_URI", null, "URL to the tarball containing the package sources")
        stringParam("RELEASE_REPO_BRANCH", null, "Branch from the -release repo to be used")
        stringParam("PACKAGE_ALIAS", null, "If not empty, package name to be used instead of PACKAGE")
        stringParam("UPLOAD_TO_REPO", null, "OSRF repo name to upload the package to")
        stringParam("OSRF_REPOS_TO_USE", null, "OSRF repos name to use when building the package")
      }

      steps {
        systemGroovyCommand("""\
          build.setDescription(
          '<b>' + build.buildVariableResolver.resolve('VERSION') + '-' + 
          build.buildVariableResolver.resolve('RELEASE_VERSION') + '</b>' +
          '(' + build.buildVariableResolver.resolve('DISTRO') + '/' + 
                build.buildVariableResolver.resolve('ARCH') + ')' +
          '<br />' +
          'branch: ' + build.buildVariableResolver.resolve('RELEASE_REPO_BRANCH') + ' | ' +
          'upload to: ' + build.buildVariableResolver.resolve('UPLOAD_TO_REPO') +
          '<br />' +
          'RTOOLS_BRANCH: ' + build.buildVariableResolver.resolve('RTOOLS_BRANCH'));
          """.stripIndent()
        )
      }

      publishers {
        archiveArtifacts('pkgs/*')

        downstreamParameterized {
	  trigger('repository_uploader_ng') {
	    condition('SUCCESS')
	    parameters {
	      currentBuild()
	      predefinedProp("PROJECT_NAME_TO_COPY_ARTIFACTS", "\${JOB_NAME}")
	    }
	  }
        }
      }
    } // end of job
  } // end of method createJob
} // end of class
