const axios = require('axios').default;
const { wrapper } = require('axios-cookiejar-support');
const tough = require('tough-cookie');
const ethers = require('ethers');
const FormData = require('form-data');
const fs = require('fs');
const path = require('path');

// Create cookie jar and client
const jar = new tough.CookieJar();
const client = wrapper(axios.create({ jar, withCredentials: true }));

// Helper functions
const generateWalletAddress = () => ethers.Wallet.createRandom().address;
const generateRandomUsername = () => `test_${Math.random().toString(36).substring(2, 8)}`;

// Test data generator
const createTestData = () => ({
  manager: {
    username: generateRandomUsername(),
    password: 'test123'
  },
  employee: {
    username: generateRandomUsername(),
    password: 'test123'
  },
  user: {
    username: generateRandomUsername(),
    password: 'test123',
    wallet_address: generateWalletAddress(),
    national_id: Math.floor(10000000000000 + Math.random() * 90000000000000).toString()
  },
  property: {
    seller_wallet_address: generateWalletAddress(),
    buyer_wallet_address: generateWalletAddress(),
    full_description: "Test property description",
    property_price: 250000.00
  }
});

// Main test function
async function runTests() {
  const testData = createTestData();
  const createdEntities = {
    managers: [],
    employees: [],
    properties: []
  };

  try {
    // Admin login
    console.log("\n=== Admin Authentication ===");
    const adminLogin = await client.post('http://localhost:5000/api/auth/login', {
      username: 'admin',
      password: 'admin'
    });
    console.log("Admin Login Response:", adminLogin.data);

    // Manager tests
    console.log("\n=== Manager Tests ===");
    
    // Create managers
    for (let i = 0; i < 2; i++) {
      const managerData = {
        username: generateRandomUsername(),
        password: 'test123'
      };
      
      try {
        console.log(`\nCreating manager ${i + 1}...`);
        const createResp = await client.post('http://localhost:5000/api/managers', managerData);
        console.log(`Create Manager ${i + 1} Response:`, createResp.data);
        
        if (createResp.data.manager) {
          createdEntities.managers.push(createResp.data.manager);
        }
      } catch (error) {
        console.log(`Error creating manager ${i + 1}:`, error.response?.data || error.message);
      }
    }

    // List managers
    console.log("\nFetching all managers...");
    const managersResp = await client.get('http://localhost:5000/api/managers');
    console.log("All Managers:", managersResp.data);

    // Delete first manager if any exist
    if (createdEntities.managers.length > 0) {
      const managerToDelete = createdEntities.managers[0];
      console.log(`\nDeleting manager ${managerToDelete.id}...`);
      try {
        const deleteResp = await client.delete(`http://localhost:5000/api/managers/${managerToDelete.id}`);
        console.log("Delete Response:", deleteResp.data);
      } catch (error) {
        console.log("Delete Error:", error.response?.data || error.message);
      }
    }

    // Employee tests
    console.log("\n=== Employee Tests ===");
    for (let i = 0; i < 2; i++) {
      const employeeData = {
        username: generateRandomUsername(),
        password: 'test123'
      };

      try {
        console.log(`\nCreating employee ${i + 1}...`);
        const createResp = await client.post('http://localhost:5000/api/employees', employeeData);
        console.log(`Create Employee ${i + 1} Response:`, createResp.data);
        
        if (createResp.data.employee) {
          createdEntities.employees.push(createResp.data.employee);
        }
      } catch (error) {
        console.log(`Error creating employee ${i + 1}:`, error.response?.data || error.message);
      }
    }

    // Cleanup
    console.log("\n=== Cleanup ===");
    
    // Delete remaining managers
    for (const manager of createdEntities.managers) {
      if (manager.id) {
        try {
          console.log(`\nDeleting manager ${manager.id}...`);
          await client.delete(`http://localhost:5000/api/managers/${manager.id}`);
        } catch (error) {
          console.log(`Error deleting manager ${manager.id}:`, error.response?.data || error.message);
        }
      }
    }

    // Delete employees
    for (const employee of createdEntities.employees) {
      if (employee.employee_id) {
        try {
          console.log(`\nDeleting employee ${employee.employee_id}...`);
          await client.delete(`http://localhost:5000/api/employees/${employee.employee_id}`);
        } catch (error) {
          console.log(`Error deleting employee ${employee.employee_id}:`, error.response?.data || error.message);
        }
      }
    }

    // Logout
    console.log("\nLogging out...");
    await client.post('http://localhost:5000/api/auth/logout');

  } catch (error) {
    console.error("\nUnexpected error during testing:", error.response?.data || error.message);
  }
}

// Run tests
runTests().catch(console.error);
