import {
    Controller,
    Get,
    Post,
    Body,
    Patch,
    Param,
    Delete,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiParam } from '@nestjs/swagger';
import { UserService } from './user.service';
import { CreateUserDto, UpdateUserDto } from './dto';
import { UserResponseDto } from './dto/user-response.dto';

@ApiTags('Users')
@Controller('users')
export class UserController {
    constructor(private readonly userService: UserService) {}

    @Post()
    @ApiOperation({ summary: 'Create a new user' })
    @ApiResponse({
        status: 201,
        description: 'User successfully created',
        type: UserResponseDto,
    })
    @ApiResponse({
        status: 400,
        description: 'Invalid input data',
    })
    @ApiResponse({
        status: 409,
        description: 'Email already exists',
    })
    async create(
        @Body() createUserDto: CreateUserDto,
    ): Promise<UserResponseDto> {
        const user = await this.userService.create(createUserDto);
        return { message: 'User created successfully', data: user };
    }

    @Get()
    @ApiOperation({ summary: 'Get all users' })
    @ApiResponse({
        status: 200,
        description: 'Users retrieved successfully',
        type: [UserResponseDto],
    })
    async findAll(): Promise<UserResponseDto[]> {
        const users = await this.userService.findAll();
        return users.map((user) => ({ data: user }));
    }

    @Get(':id')
    @ApiOperation({ summary: 'Get user by ID' })
    @ApiParam({ name: 'id', description: 'User ID' })
    @ApiResponse({
        status: 200,
        description: 'User found',
        type: UserResponseDto,
    })
    @ApiResponse({
        status: 404,
        description: 'User not found',
    })
    async findOne(@Param('id') id: string): Promise<UserResponseDto> {
        const user = await this.userService.findOne(id);
        return { data: user };
    }

    @Patch(':id')
    @ApiOperation({ summary: 'Update user by ID' })
    @ApiParam({ name: 'id', description: 'User ID' })
    @ApiResponse({
        status: 200,
        description: 'User updated successfully',
        type: UserResponseDto,
    })
    @ApiResponse({
        status: 404,
        description: 'User not found',
    })
    async update(
        @Param('id') id: string,
        @Body() updateUserDto: UpdateUserDto,
    ): Promise<UserResponseDto> {
        const user = await this.userService.update(id, updateUserDto);
        return { message: 'User updated successfully', data: user };
    }

    @Delete(':id')
    @ApiOperation({ summary: 'Delete user by ID' })
    @ApiParam({ name: 'id', description: 'User ID' })
    @ApiResponse({
        status: 204,
        description: 'User deleted successfully',
    })
    @ApiResponse({
        status: 404,
        description: 'User not found',
    })
    async remove(@Param('id') id: string): Promise<void> {
        await this.userService.remove(id);
    }
}
