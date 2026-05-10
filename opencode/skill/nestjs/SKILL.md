---
name: nestjs
description: >
  NestJS + TypeScript enterprise patterns with strict type safety and SOLID principles.
  Trigger: When writing NestJS code - controllers, services, modules, DTOs, repositories.
license: Apache-2.0
metadata:
  author: Samael死神
  version: "1.0"
---

## When to Use

- Creating new NestJS modules, controllers, services, or repositories
- Writing DTOs with validation decorators
- Setting up project structure and dependency injection
- Implementing error handling and logging
- Writing tests for NestJS applications
- Setting up database entities and TypeORM configuration

## Critical Patterns

### Architecture Flow (NEVER Skip)

```
Controllers → Services → Repositories → Database
```

### TypeScript Strict Mode (ZERO Exceptions)

- **NEVER use `any`** - Absolute prohibition
- **Explicit return types** for public methods
- **Interface over type alias** for objects
- **const over let** when possible
- **No implicit any** anywhere

### Controller Rules (HTTP ONLY)

- Handle ONLY request/response concerns
- Call services for ALL business logic
- Use DTOs with validation decorators
- Document ALL endpoints with Swagger/OpenAPI
- Return proper HTTP status codes
- **UserRequest** always for @Request() type: `@Request() req: UserRequest`
- **Proper Swagger decorators**: Use `@ApiOkResponse`, `@ApiCreatedResponse`, `@ApiNotFoundResponse`, `@ApiBadRequestResponse`, `@ApiForbiddenResponse` instead of generic `@ApiResponse`

### Service Rules (Business Logic ONLY)

- Contain ALL business rules
- Be unit testable without HTTP layer
- NO direct Request/Response usage
- Use constructor dependency injection
- NO static methods (breaks DI)

### DTO & Validation (Mandatory)

- Use class-validator decorators
- Use class-transformer for transformation
- Include @ApiProperty() for documentation
- Whitelist option to strip unknown properties
- NEVER reuse DTOs for database entities

### Error Handling

- Use Nest HttpException or custom exceptions
- NO raw Error objects
- Centralize error mapping with filters
- Log errors with context

## Code Examples

### Controller Pattern

```typescript
@ApiTags("Users")
@Controller("users")
export class UserController {
  constructor(private readonly userService: UserService) {}

  @Post()
  @ApiOperation({ summary: "Create a new user" })
  @ApiCreatedResponse({ type: UserResponseDto })
  @ApiBadRequestResponse({ description: "Invalid input" })
  async createUser(
    @Body() createUserDto: CreateUserDto,
  ): Promise<UserResponseDto> {
    const user = await this.userService.createUser(createUserDto);
    return { message: "User created", data: user };
  }
}
```

### Service Pattern

```typescript
@Injectable()
export class UserService {
  constructor(
    @InjectRepository(User)
    private userRepository: UserRepository,
    private emailService: EmailService,
  ) {}

  async createUser(createUserDto: CreateUserDto): Promise<User> {
    if (await this.userRepository.existsByEmail(createUserDto.email)) {
      throw new ConflictException("Email already exists");
    }
    const user = await this.userRepository.create(createUserDto);
    await this.emailService.sendWelcomeEmail(user.email);
    return user;
  }
}
```

### DTO Pattern

```typescript
export class CreateUserDto {
  @ApiProperty()
  @IsEmail()
  @IsNotEmpty()
  email: string;

  @ApiProperty()
  @IsString()
  @MinLength(8)
  @Matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
  password: string;
}
```

### Repository Pattern

```typescript
@Injectable()
export class UserRepository {
  constructor(
    @InjectRepository(User)
    private ormRepository: Repository<User>,
  ) {}

  async findByEmail(email: string): Promise<User | null> {
    return this.ormRepository.findOne({ where: { email } });
  }
}
```

## Commands

```bash
# Generate new resource (creates controller, service, module, DTOs)
nest g resource users

# Generate individual components
nest g module users
nest g controller users
nest g service users

# Check for circular dependencies
nest graph

# Run tests with coverage
npm run test:cov

# Run E2E tests
npm run test:e2e

# Build and validate TypeScript
npm run build
```

## Project Structure

```
src/
├── core/                    # Core infrastructure (auth, config)
├── shared/                  # Shared utilities, common modules
├── features/                # Business features
│   ├── user/
│   │   ├── dto/
│   │   ├── entities/
│   │   ├── repositories/
│   │   ├── user.controller.ts
│   │   ├── user.service.ts
│   │   ├── user.module.ts
│   │   └── *.spec.ts
│   └── patient/
├── config/
├── common/
│   ├── decorators/
│   ├── filters/
│   ├── guards/
│   ├── interceptors/
│   └── pipes/
└── main.ts
```

## Code Smells to Flag

### ❌ Fat Controllers

- Business logic in controller methods
- Direct database access
- Validation beyond DTO decorators

### ❌ Architecture Violations

- Direct DB calls outside repository layer
- Skipping layers (Controller → Repository)
- DTOs reused for persistence models

### ❌ TypeScript Violations

- Use of `any` type
- Missing type annotations
- Implicit any parameters

### ❌ Security Issues

- Unvalidated inputs
- Hardcoded secrets
- Missing authentication/authorization

## Testing Patterns

### Unit Test Structure

```typescript
describe("UserService", () => {
  let service: UserService;
  let repository: jest.Mocked<UserRepository>;

  beforeEach(async () => {
    // Setup test module
  });

  describe("createUser", () => {
    it("should create user successfully", async () => {
      // Arrange
      // Act
      // Assert
    });
  });
});
```

### Testing Requirements

- Services must have unit tests when business logic exists
- Controllers must have E2E tests for endpoints
- Coverage > 90% for business logic
- Test all HTTP status codes
- Test validation errors

## Resources

- **Templates**: See [assets/](assets/) for NestJS component templates
- **Documentation**: See [references/](references/) for local NestJS docs
