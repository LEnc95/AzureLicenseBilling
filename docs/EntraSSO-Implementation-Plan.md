# Entra ID SSO Implementation Plan

## Phase 1: Azure AD Application Setup
1. Register new application in Azure AD
   - Name: "Azure License Tracker"
   - Platform: Web
   - Redirect URI: `https://msbilling/oauth2/callback`
   - Supported account types: Single tenant

2. Configure Authentication
   - Enable ID tokens
   - Configure token authentication
   - Set up logout URL

3. Create Security Group
   - Name: "License Tracker Users"
   - Add initial admin users
   - Note down group ID for access control

4. Configure API Permissions
   - Microsoft Graph
     - User.Read
     - GroupMember.Read.All
   - Grant admin consent

5. Create Client Secret
   - Generate new client secret
   - Store securely in Secret Server
   - Note expiration date

## Phase 2: Application Code Changes

### 1. Dependencies
- Add required packages:
  ```python
  flask-azure-oauth==0.1.0
  requests==2.31.0
  ```

### 2. Secret Management
- Implement SecretManager class
- Configure Secret Server integration
- Add environment variables:
  ```
  SECRET_SERVER_URL
  SECRET_SERVER_USERNAME
  SECRET_SERVER_PASSWORD
  SECRET_ID_AZURE_CREDENTIALS
  ```

### 3. Authentication Implementation
- Add Azure AD configuration
- Implement login/logout routes
- Add session management
- Create access control decorator
- Add error handling for auth failures

### 4. Frontend Updates
- Add login/logout buttons
- Implement auth state management
- Add user info display
- Update navigation based on auth state

## Phase 3: Testing

### 1. Local Testing
- Test authentication flow
- Verify group access control
- Test error handling
- Check session management

### 2. Staging Environment
- Deploy to staging server
- Test with real Azure AD
- Verify security group access
- Test SSO integration

### 3. Security Testing
- Penetration testing
- Token validation
- Session security
- Access control verification

## Phase 4: Production Deployment

### 1. Pre-deployment Checklist
- [ ] All tests passing
- [ ] Security review completed
- [ ] Documentation updated
- [ ] Backup procedures in place
- [ ] Rollback plan prepared

### 2. Production Setup
- Configure production Azure AD app
- Set up production security group
- Configure production URLs
- Set up monitoring and logging

### 3. Deployment Steps
1. Backup current version
2. Deploy new version
3. Verify SSO functionality
4. Monitor for issues
5. Enable for all users

## Phase 5: Post-Deployment

### 1. Monitoring
- Set up application monitoring
- Configure alerting
- Monitor auth failures
- Track user access

### 2. Documentation
- Update user documentation
- Document admin procedures
- Create troubleshooting guide
- Update security documentation

### 3. Maintenance
- Schedule token rotation
- Plan for security updates
- Monitor Azure AD changes
- Regular security reviews

## Timeline
- Phase 1: 1-2 days
- Phase 2: 2-3 days
- Phase 3: 2-3 days
- Phase 4: 1-2 days
- Phase 5: Ongoing

## Success Criteria
- Successful SSO login
- Proper group access control
- Secure token handling
- Smooth user experience
- No disruption to existing functionality

## Rollback Plan
1. Keep working-version branch ready
2. Document current working configuration
3. Prepare rollback scripts
4. Test rollback procedure

## Security Considerations
- Token security
- Session management
- Access control
- Error handling
- Logging and monitoring
- Secret management
- Regular security reviews 