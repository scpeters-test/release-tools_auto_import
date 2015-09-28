import _configs_.OSRFLinuxCompilation
import _configs_.OSRFLinuxInstall
import _configs_.OSRFLinuxBuildPkg
import javaposse.jobdsl.dsl.Job

// Main platform using for quick CI
def ci_distro = [ 'trusty' ]
// Other supported platform to be checked but no for quick
// CI integration.
def other_supported_distros = [ 'trusty','vivid' ]
def supported_arches = [ 'amd64' ]

def all_supported_distros = ci_distro + other_supported_distros

// ALL JOBS
all_supported_distros.each { distro ->
  supported_arches.each { arch ->

    // --------------------------------------------------------------
    // 1. Create the default ci jobs
    def ignition_ci_job = job("ignition_transport-ci-default-${distro}-${arch}")

    // Use the linux compilation as base
    OSRFLinuxCompilation.create(ignition_ci_job)

    ignition_ci_job.with
    {
        scm {
          hg('http://bitbucket.org/ignitionrobotics/ign-transport') {
            branch('default')
            subdirectory('ignition-transport')
          }
        }

        triggers {
          scm('*/5 * * * *')
        }

        steps {
          shell("""#!/bin/bash -xe

                /bin/bash -xe ./scripts/jenkins-scripts/ign_transport-default-devel-trusty-amd64.bash
                """.stripIndent())
        }
     }
}

// CONTINUOUS INTEGRATION
ci_distro.each { distro ->
  supported_arches.each { arch ->
    // --------------------------------------------------------------
    // 1. Create the install test job
    def install_default_job = job("ignition_transport-install-pkg-${distro}-${arch}")

    // Use the linux install as base
    OSRFLinuxInstall.create(install_default_job)

    install_default_job.with
    {
        triggers {
          scm('@daily')
        }

        steps {
          shell("""#!/bin/bash -xe

                export INSTALL_JOB_PKG=libignition-transport0-dev
                export INSTALL_JOB_REPOS=stable
                /bin/bash -x ./scripts/jenkins-scripts/docker/generic-install-test-job.bash
                """.stripIndent())
       }
    }
  }
}


// --------------------------------------------------------------
// ignition-transport package builder
def build_pkg_job = job("ign-transport-debbuilder")

// Use the linux install as base
OSRFLinuxBuildPkg.create(build_pkg_job)

build_pkg_job.with
{
    steps {
      shell("""\
            #!/bin/bash -xe

            /bin/bash -x ./scripts/jenkins-scripts/docker/multidistribution-no-ros-debbuild.bash
            """.stripIndent())
    }
}
