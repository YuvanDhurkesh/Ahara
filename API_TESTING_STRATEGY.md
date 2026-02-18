# Comprehensive API Testing Strategy

## Table of Contents
1. [Executive Summary](#executive-summary)
2. [API Testing Fundamentals](#api-testing-fundamentals)
3. [Testing Pyramid for APIs](#testing-pyramid-for-apis)
4. [Testing Levels in Detail](#testing-levels-in-detail)
5. [Tools & Technology Stack](#tools--technology-stack)
6. [Implementation Roadmap](#implementation-roadmap)
7. [Best Practices](#best-practices)
8. [Common Pitfalls & Solutions](#common-pitfalls--solutions)
9. [Metrics & KPIs](#metrics--kpis)
10. [Real-World Examples](#real-world-examples)

---

## Executive Summary

API testing is the systematic validation of Application Programming Interfaces to ensure they function correctly, securely, and performantly. Unlike UI testing, API testing focuses on business logic, data validation, and system integration at the service layer.

**Why API Testing Matters:**
- **Early Detection**: Catch bugs before frontend reveals them
- **Independence**: Test without UI dependencies
- **Coverage**: Easier to test edge cases and error scenarios
- **Speed**: Faster than UI testing, runs in CI/CD quickly
- **Reliability**: Foundation for end-to-end confidence

---

## API Testing Fundamentals

### What Gets Tested

An API endpoint consists of:
- **Method** (GET, POST, PUT, DELETE, PATCH)
- **URL** (path and query parameters)
- **Request** (headers, body, authentication)
- **Response** (status code, body, headers)

### API Test Scope

**What Should Be Tested:**
1. Happy path - Normal operation
2. Error paths - Invalid inputs, edge cases
3. Integration - Multiple endpoints together
4. Performance - Response times under load
5. Security - Authentication, authorization, data protection
6. Contracts - Request/response schema compliance

---

## Testing Pyramid for APIs

```
                    ▲
                   ╱ ╲
                  ╱   ╲  E2E / Load Testing (5%)
                 ╱     ╲
                ╱───────╲
               ╱         ╲
              ╱ Integration╲ (20%)
             ╱  Testing    ╲
            ╱───────────────╲
           ╱                 ╲
          ╱  Contract Testing ╲ (25%)
         ╱   (API Schema)     ╱
        ╱─────────────────────╱
       ╱                     ╱
      ╱  Unit Testing (50%) ╱
     ╱___________________╱

- 50% Unit tests (controllers with mocks)
- 25% Contract tests (Swagger/OpenAPI)
- 20% Integration tests (multi-endpoint flows)
- 5% E2E/Load tests (complete user flows)
```

---

## Testing Levels in Detail

### Level 1: Unit Testing (Controllers)

Test controller functions with mocked dependencies.

```javascript
// tests/unit/orderController.test.js
test('should create order with valid data', async () => {
  // Mock database
  jest.spyOn(Listing, 'findById').mockResolvedValue({
    _id: 'listing-1',
    totalQuantity: 10
  });

  // Call controller
  await orderController.createOrder(mockReq, mockRes);

  // Verify response
  expect(mockRes.status).toHaveBeenCalledWith(201);
});
```

**Tools:** Jest, Mockito, Test doubles

---

### Level 2: Integration Testing (Routes)

Test actual API routes with real database.

```javascript
// tests/integration/orderRoutes.test.js
test('POST /api/orders/create returns 201', async () => {
  const res = await request(app)
    .post('/api/orders/create')
    .set('Authorization', `Bearer ${token}`)
    .send({
      listingId: 'xyz',
      quantityOrdered: 5
    });

  expect(res.status).toBe(201);
  expect(res.body.orderId).toBeDefined();
});
```

**Tools:** Jest, Supertest, Test database

---

### Level 3: Contract Testing (Schema)

Validate requests/responses against API specification.

```javascript
// tests/contract/orderContract.test.js
test('POST /orders/create requires listingId and quantityOrdered', () => {
  const schema = api.paths['/api/orders/create'].post.requestBody.schema;
  expect(schema.required).toContain('listingId');
  expect(schema.required).toContain('quantityOrdered');
});
```

**Tools:** Swagger/OpenAPI, swagger-parser

---

### Level 4: Workflow Testing

Test multi-step user workflows.

```javascript
test('Seller creates listing → Buyer orders → Payment', async () => {
  // Step 1: Create listing
  const listingRes = await createListing(sellerToken);
  const listingId = listingRes.body.listingId;

  // Step 2: Order
  const orderRes = await createOrder(buyerToken, listingId);
  const orderId = orderRes.body.orderId;

  // Step 3: Process payment
  const paymentRes = await processPayment(buyerToken, orderId);
  expect(paymentRes.status).toBe(200);
});
```

---

### Level 5: Security Testing

Validate authentication, authorization, and data protection.

```javascript
test('unauthorized users cannot create orders', async () => {
  const res = await request(app)
    .post('/api/orders/create')
    .send({ listingId: 'xyz' });

  expect(res.status).toBe(401);
});

test('users cannot access other users data', async () => {
  const res = await request(app)
    .get(`/api/orders/${otherUserOrderId}`)
    .set('Authorization', `Bearer ${token}`);

  expect(res.status).toBe(403);
});
```

---

### Level 6: Performance Testing

Test API under load and measure response times.

```bash
artillery run load-test.yml
```

**Config:**
```yaml
config:
  target: "http://localhost:5000"
  phases:
    - duration: 60
      arrivalRate: 10  # 10 requests/sec
    - duration: 120
      arrivalRate: 20  # ramp to 20 req/sec
```

---

### Level 7: Error Scenario Testing

Systematically test error conditions.

```javascript
test('returns 400 for invalid JSON', () => { ... });
test('returns 422 for semantic errors', () => { ... });
test('returns 401 without authorization', () => { ... });
test('returns 404 for nonexistent resource', () => { ... });
test('handles race conditions correctly', () => { ... });
```

---

## Tools & Technology Stack

### Recommended Tools

| Tool | Purpose | Integration |
|------|---------|-------------|
| Jest | Unit/integration testing | `npm test` |
| Supertest | HTTP assertions | `npm test` |
| Swagger/OpenAPI | API contract | `http://localhost:5000/api-docs` |
| Postman | Workflow testing | `newman run collection.json` |
| REST Client | Manual testing | `backend/api_test.http` |
| Artillery | Load testing | `artillery run load-test.yml` |
| Snyk | Security scanning | `snyk test backend/` |

---

## Implementation Roadmap

### Phase 1: Foundation (Week 1)
- Unit tests with Jest
- Basic integration tests
- Test structure setup

### Phase 2: Expansion (Week 2-3)
- Swagger documentation
- Postman collections
- Contract tests

### Phase 3: Advanced (Week 4)
- Load testing with Artillery
- Security testing
- Workflow validation

### Phase 4: CI/CD (Week 5)
- GitHub Actions automation
- Automated deployments
- Performance tracking

---

## Best Practices

### 1. Test Data Isolation
```javascript
beforeEach(async () => {
  await Order.deleteMany({});
});
```

### 2. Meaningful Assertions
```javascript
// ✅ Good
expect(res.status).toBe(201);
expect(res.body.orderId).toMatch(/^[a-f0-9]{24}$/);

// ❌ Bad
expect(res.body).toBeDefined();
```

### 3. Independent Tests
```javascript
// ✅ Good: Each test is complete
test('can create and retrieve order', () => {
  const order = await createOrder();
  const retrieved = await getOrder(order.id);
});

// ❌ Bad: Test B depends on Test A
test('A: Create order', () => { orderId = ... });
test('B: Get order', () => { getOrder(orderId) });
```

### 4. Realistic Test Data
```javascript
const testListing = {
  foodName: 'Fresh Apples',
  totalQuantity: 50,
  quantityUnit: 'kg',
  pricing: { discountedPrice: 250 },
  pickupWindow: { from: ..., to: ... }
};
```

---

## Common Pitfalls & Solutions

### Pitfall 1: Over-Mocking
```javascript
// ❌ Bad: Mock too much
jest.spyOn(Listing, 'findById').mockResolvedValue(...);
jest.spyOn(Order, 'create').mockResolvedValue(...);
// Tests the mock, not the code!

// ✅ Good: Mock only external services
jest.spyOn(emailService, 'send').mockResolvedValue(true);
```

### Pitfall 2: Not Testing Error Paths
```javascript
// ❌ Bad
test('should create order', () => { ... });

// ✅ Good
test('should create order with valid data', () => { ... });
test('should reject quantity exceeding available', () => { ... });
test('should reject without authorization', () => { ... });
```

### Pitfall 3: Flaky Tests
```javascript
// ❌ Bad: Timing-dependent
await createOrder();
const orders = await getOrders();  // Might not exist yet!

// ✅ Good: Explicit wait
await waitFor(() => getOrders(), orders => 
  orders.some(o => o.id === expectedId)
);
```

---

## Metrics & KPIs

### Coverage Targets
- Controllers: ≥80%
- Routes: ≥90%
- Overall: ≥70%

### Test Metrics
- Pass rate: ≥98%
- Execution time: <60 seconds
- Flakiness: <1%

### API Quality
- Response time P95: <1 second
- Success rate: ≥99.5%
- Error handling: All codes documented

---

## Real-World Examples

### Example 1: Order Workflow
```javascript
test('complete order workflow', async () => {
  // Create listing
  const listing = await createListing(sellerToken, {
    foodName: 'Apples',
    quantity: 50
  });

  // Create order
  const order = await createOrder(buyerToken, {
    listingId: listing.id,
    quantity: 10
  });

  // Process payment
  const payment = await processPayment(buyerToken, {
    orderId: order.id,
    amount: 250
  });

  // Verify results
  expect(order.status).toBe('placed');
  expect(payment.status).toBe('completed');
});
```

### Example 2: Error Handling
```javascript
describe('error scenarios', () => {
  test('returns 400 for missing fields', async () => {
    const res = await createOrder(token, {
      // Missing listingId
      quantity: 5
    });
    expect(res.status).toBe(400);
  });

  test('returns 422 for invalid quantity', async () => {
    const res = await createOrder(token, {
      listingId: 'xyz',
      quantity: 999  // Exceeds available
    });
    expect(res.status).toBe(422);
  });
});
```

---

## Summary

**Effective API Testing requires:**
1. **Multi-level approach** - unit, integration, contract, E2E
2. **Automation** - CI/CD integration
3. **Realistic scenarios** - actual workflows
4. **Error coverage** - edge cases
5. **Performance validation** - load testing

**Expected ROI:**
- Catch bugs early
- Enable rapid iteration
- Confidence in deployments
- Production stability
