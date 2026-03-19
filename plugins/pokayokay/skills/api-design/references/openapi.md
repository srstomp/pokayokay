# OpenAPI Specification

API documentation with OpenAPI (Swagger).

## Basic Structure

```yaml
openapi: 3.1.0

info:
  title: My API
  version: 1.0.0
  description: API for managing users and orders
  contact:
    name: API Support
    email: api@example.com
    url: https://docs.example.com
  license:
    name: MIT
    url: https://opensource.org/licenses/MIT

servers:
  - url: https://api.example.com/v1
    description: Production
  - url: https://staging-api.example.com/v1
    description: Staging
  - url: http://localhost:3000/v1
    description: Local development

tags:
  - name: Users
    description: User management operations
  - name: Orders
    description: Order management operations

paths:
  # Endpoints defined here
  
components:
  # Reusable schemas, parameters, responses
```

---

## Paths and Operations

### Basic Endpoint

```yaml
paths:
  /users:
    get:
      summary: List all users
      description: Returns a paginated list of users
      operationId: listUsers
      tags:
        - Users
      parameters:
        - $ref: '#/components/parameters/PageParam'
        - $ref: '#/components/parameters/LimitParam'
      responses:
        '200':
          description: Successful response
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/UserList'
        '401':
          $ref: '#/components/responses/Unauthorized'
    
    post:
      summary: Create a new user
      description: Creates a new user account
      operationId: createUser
      tags:
        - Users
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateUserRequest'
      responses:
        '201':
          description: User created
          headers:
            Location:
              description: URL of created user
              schema:
                type: string
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
        '400':
          $ref: '#/components/responses/ValidationError'
        '409':
          $ref: '#/components/responses/Conflict'
```

### Resource with ID

```yaml
paths:
  /users/{userId}:
    parameters:
      - name: userId
        in: path
        required: true
        description: The user ID
        schema:
          type: string
          format: uuid
    
    get:
      summary: Get user by ID
      operationId: getUser
      tags:
        - Users
      responses:
        '200':
          description: Successful response
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
        '404':
          $ref: '#/components/responses/NotFound'
    
    put:
      summary: Update user
      operationId: updateUser
      tags:
        - Users
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/UpdateUserRequest'
      responses:
        '200':
          description: User updated
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
        '404':
          $ref: '#/components/responses/NotFound'
    
    delete:
      summary: Delete user
      operationId: deleteUser
      tags:
        - Users
      responses:
        '204':
          description: User deleted
        '404':
          $ref: '#/components/responses/NotFound'
```

---

## Components

### Schemas

```yaml
components:
  schemas:
    # Base user schema
    User:
      type: object
      required:
        - id
        - email
        - name
      properties:
        id:
          type: string
          format: uuid
          readOnly: true
          example: "123e4567-e89b-12d3-a456-426614174000"
        email:
          type: string
          format: email
          example: "user@example.com"
        name:
          type: string
          minLength: 1
          maxLength: 100
          example: "John Doe"
        role:
          type: string
          enum: [user, admin, moderator]
          default: user
        createdAt:
          type: string
          format: date-time
          readOnly: true
        updatedAt:
          type: string
          format: date-time
          readOnly: true
    
    # Create request (subset of User)
    CreateUserRequest:
      type: object
      required:
        - email
        - name
        - password
      properties:
        email:
          type: string
          format: email
        name:
          type: string
          minLength: 1
          maxLength: 100
        password:
          type: string
          format: password
          minLength: 8
        role:
          type: string
          enum: [user, admin]
    
    # Update request (all optional)
    UpdateUserRequest:
      type: object
      properties:
        email:
          type: string
          format: email
        name:
          type: string
          minLength: 1
          maxLength: 100
        role:
          type: string
          enum: [user, admin]
    
    # List response with pagination
    UserList:
      type: object
      required:
        - data
        - meta
      properties:
        data:
          type: array
          items:
            $ref: '#/components/schemas/User'
        meta:
          $ref: '#/components/schemas/PaginationMeta'
        links:
          $ref: '#/components/schemas/PaginationLinks'
    
    # Pagination metadata
    PaginationMeta:
      type: object
      properties:
        total:
          type: integer
          example: 100
        page:
          type: integer
          example: 1
        perPage:
          type: integer
          example: 20
        totalPages:
          type: integer
          example: 5
    
    PaginationLinks:
      type: object
      properties:
        self:
          type: string
        first:
          type: string
        prev:
          type: string
          nullable: true
        next:
          type: string
          nullable: true
        last:
          type: string
```

### Error Schemas

```yaml
components:
  schemas:
    Error:
      type: object
      required:
        - error
      properties:
        error:
          type: object
          required:
            - status
            - code
            - message
          properties:
            status:
              type: integer
              example: 400
            code:
              type: string
              example: "VALIDATION_ERROR"
            message:
              type: string
              example: "Request validation failed"
            requestId:
              type: string
              example: "req_abc123"
            timestamp:
              type: string
              format: date-time
            details:
              type: array
              items:
                $ref: '#/components/schemas/ValidationErrorDetail'
    
    ValidationErrorDetail:
      type: object
      properties:
        field:
          type: string
          example: "email"
        code:
          type: string
          example: "INVALID_FORMAT"
        message:
          type: string
          example: "Must be a valid email address"
        value:
          description: The invalid value that was provided
```

### Parameters

```yaml
components:
  parameters:
    PageParam:
      name: page
      in: query
      description: Page number
      schema:
        type: integer
        minimum: 1
        default: 1
    
    LimitParam:
      name: limit
      in: query
      description: Items per page
      schema:
        type: integer
        minimum: 1
        maximum: 100
        default: 20
    
    SortParam:
      name: sort
      in: query
      description: Sort field and direction
      schema:
        type: string
        example: "-createdAt"
    
    SearchParam:
      name: q
      in: query
      description: Search query
      schema:
        type: string
    
    IncludeParam:
      name: include
      in: query
      description: Related resources to include
      schema:
        type: string
        example: "orders,profile"
```

### Responses

```yaml
components:
  responses:
    NotFound:
      description: Resource not found
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
          example:
            error:
              status: 404
              code: "NOT_FOUND"
              message: "Resource not found"
    
    Unauthorized:
      description: Authentication required
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
          example:
            error:
              status: 401
              code: "UNAUTHORIZED"
              message: "Authentication required"
    
    Forbidden:
      description: Insufficient permissions
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
          example:
            error:
              status: 403
              code: "FORBIDDEN"
              message: "You don't have permission to access this resource"
    
    ValidationError:
      description: Validation error
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
          example:
            error:
              status: 400
              code: "VALIDATION_ERROR"
              message: "Validation failed"
              details:
                - field: "email"
                  code: "INVALID_FORMAT"
                  message: "Must be a valid email"
    
    Conflict:
      description: Resource conflict
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
          example:
            error:
              status: 409
              code: "DUPLICATE_RESOURCE"
              message: "Resource already exists"
    
    RateLimited:
      description: Rate limit exceeded
      headers:
        Retry-After:
          schema:
            type: integer
          description: Seconds to wait before retrying
        X-RateLimit-Limit:
          schema:
            type: integer
        X-RateLimit-Remaining:
          schema:
            type: integer
        X-RateLimit-Reset:
          schema:
            type: integer
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
```

