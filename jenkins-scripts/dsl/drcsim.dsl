import _configs_.*
import javaposse.jobdsl.dsl.Job

def supported_distros = [ 'trusty' ]
def supported_arches = [ 'amd64' ]

def drcsim_packages = [ 'drcsim', 'drcsim5', 'drcsim7' ]

// LINUX
drcsim_packages.each { pkg ->

  if ("${pkg}" == "drcsim")
  {
     gazebo_deb_pkg = "libgazebo4-dev"
  }
  else if ("${pkg}" == "drcsim5")
  {
     gazebo_deb_pkg = "libgazebo5-dev"
  }
  else if ("${pkg}" == "drcsim7")
  {
     gazebo_deb_pkg = "libgazebo7-dev"
  }

  supported_distros.each { distro ->
    supported_arches.each { arch ->
      // --------------------------------------------------------------
      // 1. Create the default ci jobs
      def drcsim_ci_job = job("${pkg}-ci-default-${distro}-${arch}")
      OSRFLinuxCompilation.create(drcsim_ci_job)

      drcsim_ci_job.with
      {
          label "gpu-reliable-${distro}"

          scm {
            hg("http://bitbucket.org/osrf/drcsim") {
              branch('default')
              subdirectory("drcsim")
            }
          }

          triggers {
            scm('*/5 * * * *')
          }

          steps {
            shell("""\
                  #!/bin/bash -xe

                  export DISTRO=${distro}
                  export ARCH=${arch}
                  export GZ_PACKAGE_TO_USE_IN_ROS=${gazebo_deb_pkg}

                  /bin/bash -xe ./scripts/jenkins-scripts/docker/drcsim-compilation.bash
                  """.stripIndent())
          }
      }
   
      // --------------------------------------------------------------
      // 2. Create the ANY job
      def drcsim_ci_any_job = job("${pkg}-ci_any-default-${distro}-${arch}")
      OSRFLinuxCompilationAny.create(drcsim_ci_any_job,
                                    "http://bitbucket.org/osrf/drcsim")
      drcsim_ci_any_job.with
      {
          if ("${pkg}" == 'drcsim')
          {
            label "gpu-reliable-${distro}"
          }

          steps 
          {
            shell("""\
                  export DISTRO=${distro}
                  export ARCH=${arch}
                  export GZ_PACKAGE_TO_USE_IN_ROS=${gazebo_deb_pkg}

                  /bin/bash -xe ./scripts/jenkins-scripts/docker/drcsim-compilation.bash
                  """.stripIndent())
          }
      }

      // --------------------------------------------------------------
      // 3. Testing online installation
      def install_default_job = job("${pkg}-install-pkg-${distro}-${arch}")
      OSRFLinuxInstall.create(install_default_job)

      install_default_job.with
      {
         label "gpu-reliable-${distro}"

         triggers {
            cron('@daily')
         }

          steps {
            shell("""\
                  #!/bin/bash -xe

                  export INSTALL_JOB_PKG=${pkg}
                  export INSTALL_JOB_REPOS=stable
                  /bin/bash -x ./scripts/jenkins-scripts/docker/drcsim-install-test-job.bash
                  """.stripIndent())
         }
      }
    }
  }
}
