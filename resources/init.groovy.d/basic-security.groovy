#!groovy
import hudson.*
import hudson.security.*
import jenkins.*
import jenkins.model.*
import hudson.model.*;
import hudson.security.*;

def instance = Jenkins.getInstance()
def env = System.getenv()

String jenkins_user = env['JENKINS_USER'].toString()
String jenkins_password = env['JENKINS_PASSWORD'].toString()

println "--> Creating local user ${jenkins_user}"

def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount(jenkins_user,jenkins_password)
instance.setSecurityRealm(hudsonRealm)

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)
instance.save()
