def project_name="math"
def branch="default"
def CI_platform_reference="trusty"
def ubuntu_releases="precise trusty"

def default_jobs_days_to_keep=15
def default_jobs_priority=100

def download_release_tools="#!/bin/bash -x \n" +
                           "[[ -d ./scripts ]] &&  rm -fr ./scripts \n" +
                           "hg clone http://bitbucket.org/osrf/release-tools scripts \n"
ubuntu_releases.each() {
  def ubuntu_platform=${it}
  def release_tools_run_gui=download_release_tools + "\n"
                            "/bin/bash -x ./scripts/jenkins-scripts/"+
                            "ign_${project_name}-default-gui-test-devel-${ubuntu_platform}-amd64.bash\n"
  def release_tools_run=download_release_tools + "\n"
                            "/bin/bash -x ./scripts/jenkins-scripts/"+
                            "ign_${project_name}-default-devel-${ubuntu_platform}-amd64.bash\n"

  print "Generating job for ${ubuntu_platform}"

  // Default jobs
  // -default + branches
  job {
    name "DSL-ignition-${project_name}-default-devel-${ubuntu_platform}-amd64"

    if (ubuntu_platform = CI_platform_reference) 
    {
       description("Continuous integration job for ${branch} run on every change") 
    }
    else
    {
       description("CI job for ${branch} run once a day")
    }
    
    // time to keep job log information
    logRotator(default_jobs_days_to_keep)
    
    // job priority  
    priority(default_jobs_priority)

    // specify which nodes can run this job
    if (ubuntu_platform = CI_platform_reference) 
    {
        label("gpu-nvidia-${ubuntu_platform}")
    }
    else
    {
        label("slave")
    }

    scm {
        // TODO: config directory and some other goodies 
        hg("https://bitbucket.org/ignitionrobotics/ign-${project_name}" , branch)
    }

    triggers {
        // For continuous integration we check every five minutes. For the rest
        // of platforms, just once a day
        if (ubuntu_platform = CI_platform_reference)
        {
          scm('*/5 * * * *')
        }
        else
        {
          scm('H H * * *')
        }
    }
    steps {
        shell(
               download_release_tools + "\n" +
/bin/bash -x ./scripts/jenkins-scripts/gazebo-default-gui-test-devel-raring-amd64.bash
 )
    }
  }
}

# Any jobs
# windows + homebrew + CI_ref + 
