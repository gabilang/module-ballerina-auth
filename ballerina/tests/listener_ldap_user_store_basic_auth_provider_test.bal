// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/test;

isolated function getLdapUserStoreConfig() returns LdapUserStoreConfig {
    LdapUserStoreConfig ldapUserStoreConfig = {
        domainName: "avix.lk",
        connectionUrl: "ldap://localhost:389",
        connectionName: "cn=admin,dc=avix,dc=lk",
        connectionPassword: "avix123",
        userSearchBase: "ou=Users,dc=avix,dc=lk",
        userEntryObjectClass: "inetOrgPerson",
        userNameAttribute: "uid",
        userNameSearchFilter: "(&(objectClass=inetOrgPerson)(uid=?))",
        userNameListFilter: "(objectClass=inetOrgPerson)",
        groupSearchBase: ["ou=Groups,dc=avix,dc=lk"],
        groupEntryObjectClass: "groupOfNames",
        groupNameAttribute: "cn",
        groupNameSearchFilter: "(&(objectClass=groupOfNames)(cn=?))",
        groupNameListFilter: "(objectClass=groupOfNames)",
        membershipAttribute: "member",
        userRolesCacheEnabled: true,
        connectionPoolingEnabled: false,
        connectionTimeout: 5,
        readTimeout: 60
    };
    return ldapUserStoreConfig;
}

isolated function getLdapsUserStoreConfig1() returns LdapUserStoreConfig {
    LdapUserStoreConfig ldapsUserStoreConfig = {
        domainName: "avix.lk",
        connectionUrl: "ldaps://localhost:636",
        connectionName: "cn=admin,dc=avix,dc=lk",
        connectionPassword: "avix123",
        userSearchBase: "ou=Users,dc=avix,dc=lk",
        userEntryObjectClass: "inetOrgPerson",
        userNameAttribute: "uid",
        userNameSearchFilter: "(&(objectClass=inetOrgPerson)(uid=?))",
        userNameListFilter: "(objectClass=inetOrgPerson)",
        groupSearchBase: ["ou=Groups,dc=avix,dc=lk"],
        groupEntryObjectClass: "groupOfNames",
        groupNameAttribute: "cn",
        groupNameSearchFilter: "(&(objectClass=groupOfNames)(cn=?))",
        groupNameListFilter: "(objectClass=groupOfNames)",
        membershipAttribute: "member",
        userRolesCacheEnabled: true,
        connectionPoolingEnabled: false,
        connectionTimeout: 5,
        readTimeout: 60,
        secureSocket: {
            cert: PUBLIC_CERT_PATH
        }
    };
    return ldapsUserStoreConfig;
}

isolated function getLdapsUserStoreConfig2() returns LdapUserStoreConfig {
    LdapUserStoreConfig ldapsUserStoreConfig = {
        domainName: "avix.lk",
        connectionUrl: "ldaps://localhost:636",
        connectionName: "cn=admin,dc=avix,dc=lk",
        connectionPassword: "avix123",
        userSearchBase: "ou=Users,dc=avix,dc=lk",
        userEntryObjectClass: "inetOrgPerson",
        userNameAttribute: "uid",
        userNameSearchFilter: "(&(objectClass=inetOrgPerson)(uid=?))",
        userNameListFilter: "(objectClass=inetOrgPerson)",
        groupSearchBase: ["ou=Groups,dc=avix,dc=lk"],
        groupEntryObjectClass: "groupOfNames",
        groupNameAttribute: "cn",
        groupNameSearchFilter: "(&(objectClass=groupOfNames)(cn=?))",
        groupNameListFilter: "(objectClass=groupOfNames)",
        membershipAttribute: "member",
        userRolesCacheEnabled: true,
        connectionPoolingEnabled: false,
        connectionTimeout: 5,
        readTimeout: 60,
        secureSocket: {
            cert: {
                path: TRUSTSTORE_PATH,
                password: "ballerina"
            }
        }
    };
    return ldapsUserStoreConfig;
}

@test:Config {
    groups: ["ldap"]
}
isolated function testLdapAuthenticationEmptyCredential() {
    string usernameAndPassword = "";
    ListenerLdapUserStoreBasicAuthProvider basicAuthProvider = new(getLdapUserStoreConfig());
    string credential = usernameAndPassword.toBytes().toBase64();
    UserDetails|Error result = basicAuthProvider.authenticate(credential);
    if result is Error {
        test:assertEquals(result.message(), "Credential cannot be empty.");
    } else {
        test:assertFail("Expected error not found.");
    }
}

@test:Config {
    groups: ["ldap"]
}
isolated function testLdapAuthenticationOfNonExistingUser() {
    string usernameAndPassword = "dave:123";
    ListenerLdapUserStoreBasicAuthProvider basicAuthProvider = new(getLdapUserStoreConfig());
    string credential = usernameAndPassword.toBytes().toBase64();
    UserDetails|Error result = basicAuthProvider.authenticate(credential);
    if result is Error {
        test:assertEquals(result.message(), "Failed to authenticate username 'dave' with LDAP user store.");
    } else {
        test:assertFail("Expected error not found.");
    }
}

@test:Config {
    groups: ["ldap"]
}
isolated function testLdapAuthenticationOfInvalidPassword() {
    string usernameAndPassword = "alice:invalid";
    ListenerLdapUserStoreBasicAuthProvider basicAuthProvider = new(getLdapUserStoreConfig());
    string credential = usernameAndPassword.toBytes().toBase64();
    UserDetails|Error result = basicAuthProvider.authenticate(credential);
    if result is Error {
        test:assertEquals(result.message(), "Failed to authenticate username 'alice' with LDAP user store.");
    } else {
        test:assertFail("Expected error not found.");
    }
}

@test:Config {
    groups: ["ldap"]
}
isolated function testLdapAuthenticationSuccessForUser() returns Error? {
    string usernameAndPassword = "alice:alice@123";
    ListenerLdapUserStoreBasicAuthProvider basicAuthProvider = new(getLdapUserStoreConfig());
    string credential = usernameAndPassword.toBytes().toBase64();
    UserDetails result = check basicAuthProvider.authenticate(credential);
    test:assertEquals(result.username, "alice");
    test:assertEquals(result?.scopes, ["developer"]);
}

@test:Config {
    groups: ["ldap"]
}
isolated function testLdapAuthenticationSuccessForSuperUser()returns Error? {
    string usernameAndPassword = "ldclakmal:ldclakmal@123";
    ListenerLdapUserStoreBasicAuthProvider basicAuthProvider = new(getLdapUserStoreConfig());
    string credential = usernameAndPassword.toBytes().toBase64();
    UserDetails result = check basicAuthProvider.authenticate(credential);
    test:assertEquals(result.username, "ldclakmal");
    test:assertEquals(result?.scopes, ["admin", "developer"]);
}

@test:Config {
    groups: ["ldap"]
}
isolated function testLdapAuthenticationWithEmptyUsername() {
    string usernameAndPassword = ":xxx";
    ListenerLdapUserStoreBasicAuthProvider basicAuthProvider = new(getLdapUserStoreConfig());
    string credential = usernameAndPassword.toBytes().toBase64();
    UserDetails|Error result = basicAuthProvider.authenticate(credential);
    if result is Error {
        test:assertEquals(result.message(), "Incorrect credential format. Format should be username:password");
    } else {
        test:assertFail("Expected error not found.");
    }
}

@test:Config {
    groups: ["ldap"]
}
isolated function testLdapAuthenticationWithEmptyPassword() {
    string usernameAndPassword = "alice:";
    ListenerLdapUserStoreBasicAuthProvider basicAuthProvider = new(getLdapUserStoreConfig());
    string credential = usernameAndPassword.toBytes().toBase64();
    UserDetails|Error result = basicAuthProvider.authenticate(credential);
    if result is Error {
        test:assertEquals(result.message(), "Incorrect credential format. Format should be username:password");
    } else {
        test:assertFail("Expected error not found.");
    }
}

@test:Config {
    groups: ["ldap"]
}
isolated function testLdapAuthenticationWithEmptyPasswordAndInvalidUsername() {
    string usernameAndPassword = "invalid:";
    ListenerLdapUserStoreBasicAuthProvider basicAuthProvider = new(getLdapUserStoreConfig());
    string credential = usernameAndPassword.toBytes().toBase64();
    UserDetails|Error result = basicAuthProvider.authenticate(credential);
    if result is Error {
        test:assertEquals(result.message(), "Incorrect credential format. Format should be username:password");
    } else {
        test:assertFail("Expected error not found.");
    }
}

@test:Config {
    groups: ["ldap"]
}
isolated function testLdapAuthenticationWithEmptyUsernameAndEmptyPassword() {
    string usernameAndPassword = ":";
    ListenerLdapUserStoreBasicAuthProvider basicAuthProvider = new(getLdapUserStoreConfig());
    string credential = usernameAndPassword.toBytes().toBase64();
    UserDetails|Error result = basicAuthProvider.authenticate(credential);
    if result is Error {
        test:assertEquals(result.message(), "Incorrect credential format. Format should be username:password");
    } else {
        test:assertFail("Expected error not found.");
    }
}

@test:Config {
    groups: ["ldap"]
}
isolated function testLdapAuthenticationFailureWithLdaps1() {
    ListenerLdapUserStoreBasicAuthProvider|error basicAuthProvider = trap new(getLdapsUserStoreConfig1());
    if basicAuthProvider is error {
        assertContains(basicAuthProvider, "PKIX path building failed");
    } else {
        test:assertFail("Expected error not found.");
    }
}

@test:Config {
    groups: ["ldap"]
}
isolated function testLdapAuthenticationFailureWithLdaps2() {
    ListenerLdapUserStoreBasicAuthProvider|error basicAuthProvider = trap new(getLdapsUserStoreConfig2());
    if basicAuthProvider is error {
        assertContains(basicAuthProvider, "PKIX path building failed");
    } else {
        test:assertFail("Expected error not found.");
    }
}
