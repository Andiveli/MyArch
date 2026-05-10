import { Injectable } from '@nestjs/common';
import { CreateUserDto, UpdateUserDto } from './dto';
import { User } from './entities/user.entity';
import { UserRepository } from './repositories/user.repository';

@Injectable()
export class UserService {
    constructor(private readonly userRepository: UserRepository) {}

    async create(createUserDto: CreateUserDto): Promise<User> {
        // Business logic here
        if (await this.userRepository.existsByEmail(createUserDto.email)) {
            throw new ConflictException('Email already exists');
        }

        return this.userRepository.create(createUserDto);
    }

    async findAll(): Promise<User[]> {
        return this.userRepository.findAll();
    }

    async findOne(id: string): Promise<User> {
        const user = await this.userRepository.findById(id);
        if (!user) {
            throw new NotFoundException(`User with ID ${id} not found`);
        }
        return user;
    }

    async update(id: string, updateUserDto: UpdateUserDto): Promise<User> {
        await this.findOne(id); // Verify user exists
        return this.userRepository.update(id, updateUserDto);
    }

    async remove(id: string): Promise<void> {
        await this.findOne(id); // Verify user exists
        await this.userRepository.delete(id);
    }
}
