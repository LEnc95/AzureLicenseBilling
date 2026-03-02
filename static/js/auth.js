// Authentication and security group handling
class AuthManager {
    constructor() {
        this.accessToken = null;
        this.isAuthenticated = false;
        this.errorMessage = null;
        this.initializationPromise = null;
        this.retryCount = 0;
        this.maxRetries = 3;
    }

    async initialize() {
        // If already initializing, return the existing promise
        if (this.initializationPromise) {
            return this.initializationPromise;
        }

        this.initializationPromise = (async () => {
            try {
                // Get access token
                const response = await fetch('/api/token');
                if (!response.ok) {
                    throw new Error(`Failed to get access token: ${response.statusText}`);
                }
                const data = await response.json();
                this.accessToken = data.access_token;
                this.isAuthenticated = true;
                this.errorMessage = null;
                this.retryCount = 0; // Reset retry count on successful authentication
                
                // Update UI immediately after successful authentication
                updateUI();
                return true;
            } catch (error) {
                this.errorMessage = 'Authentication failed: ' + error.message;
                this.isAuthenticated = false;
                this.accessToken = null;
                
                // Update UI to show authentication failure
                updateUI();
                throw error;
            } finally {
                // Clear the initialization promise after completion
                this.initializationPromise = null;
            }
        })();

        return this.initializationPromise;
    }

    async makeAuthenticatedRequest(url, options = {}) {
        if (!this.accessToken) {
            // If no token, try to initialize once
            try {
                await this.initialize();
            } catch (error) {
                throw new Error('Authentication required. Please refresh the page.');
            }
        }

        const headers = {
            'Authorization': `Bearer ${this.accessToken}`,
            'Content-Type': 'application/json',
            ...options.headers
        };

        try {
            const response = await fetch(url, {
                ...options,
                headers
            });

            if (response.status === 401) {
                // Check if we've exceeded max retries
                if (this.retryCount >= this.maxRetries) {
                    this.isAuthenticated = false;
                    this.accessToken = null;
                    throw new Error('Maximum authentication retry attempts reached. Please refresh the page.');
                }
                
                // Increment retry count
                this.retryCount++;
                
                // Token might be expired, try to reinitialize once
                await this.initialize();
                
                // Make one final attempt with the new token
                const retryResponse = await fetch(url, {
                    ...options,
                    headers: {
                        'Authorization': `Bearer ${this.accessToken}`,
                        'Content-Type': 'application/json',
                        ...options.headers
                    }
                });

                if (!retryResponse.ok) {
                    throw new Error(`Request failed after retry: ${retryResponse.statusText}`);
                }

                return await retryResponse.json();
            }

            if (response.status === 403) {
                throw new Error('You do not have permission to access this resource. Please contact your administrator.');
            }

            if (!response.ok) {
                throw new Error(`Request failed: ${response.statusText}`);
            }

            return await response.json();
        } catch (error) {
            this.errorMessage = error.message;
            throw error;
        }
    }

    getErrorMessage() {
        return this.errorMessage;
    }

    isUserAuthenticated() {
        return this.isAuthenticated && this.accessToken !== null;
    }
}

// Create a global instance
const authManager = new AuthManager();

// Initialize authentication when the page loads
document.addEventListener('DOMContentLoaded', async () => {
    try {
        await authManager.initialize();
        // Update UI based on authentication status
        updateUI();
    } catch (error) {
        console.error('Authentication failed:', error);
        showError(error.message);
    }
});

// Update UI elements based on authentication status
function updateUI() {
    const authStatus = document.getElementById('auth-status');
    if (authStatus) {
        authStatus.textContent = authManager.isUserAuthenticated() ? 'Authenticated' : 'Not Authenticated';
        authStatus.className = authManager.isUserAuthenticated() ? 'authenticated' : 'not-authenticated';
    }
}

// Show error message to user
function showError(message) {
    const errorDiv = document.getElementById('error-message');
    if (errorDiv) {
        errorDiv.textContent = message;
        errorDiv.style.display = 'block';
    }
}

// Example of making an authenticated request
async function fetchLicenseData() {
    try {
        const data = await authManager.makeAuthenticatedRequest('/api/licenses');
        // Handle the data
        return data;
    } catch (error) {
        showError(error.message);
        throw error;
    }
} 