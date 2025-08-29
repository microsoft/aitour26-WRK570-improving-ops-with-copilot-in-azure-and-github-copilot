import { test, expect } from '@playwright/test';
// @ts-ignore
const testConfig = require('../../test-config');

test.describe('store-front-api tests', () => {
  test.skip(!testConfig.isStoreFrontConfigured(), 'testConfig.storeFrontUrl is not set');

  test('should return valid products JSON', async ({ page }) => {
    const storeFrontApiUrl = testConfig.storeFrontUrl.replace(/\/+$/, '') + '/api/products';
    
    for (let i = 0; i < 20; i++) {
        // Make API request and get JSON response
        const response = await page.request.get(storeFrontApiUrl);
        
        // Check response status
        expect(response.ok()).toBeTruthy();
        expect(response.status()).toBe(200);
        
        // Check content type
        expect(response.headers()['content-type']).toContain('application/json');
        
        // Parse and validate JSON
        const products = await response.json();
        
        // Validate JSON structure
        expect(Array.isArray(products)).toBeTruthy();
        expect(products.length).toBeGreaterThan(0);
        
        // Validate first product structure
        const firstProduct = products[0];
        expect(firstProduct).toHaveProperty('id');
        expect(firstProduct).toHaveProperty('name');
        expect(firstProduct).toHaveProperty('price');
        
        // Validate specific values
        expect(typeof firstProduct.id).toBe('number');
        expect(typeof firstProduct.name).toBe('string');
        expect(firstProduct.name).toContain(testConfig.companyName);
        // wait for one second before next iteration
        await new Promise(resolve => setTimeout(resolve, 1000));
        await page.goBack();
    }

  });



});