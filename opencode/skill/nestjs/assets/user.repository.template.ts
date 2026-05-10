import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../entities/user.entity';
import { CreateUserDto, UpdateUserDto } from '../dto';

@Injectable()
export class UserRepository {
    constructor(
        @InjectRepository(User)
        private readonly ormRepository: Repository<User>,
    ) {}

    async create(createUserDto: CreateUserDto): Promise<User> {
        const user = this.ormRepository.create(createUserDto);
        return this.ormRepository.save(user);
    }

    async findAll(): Promise<User[]> {
        return this.ormRepository.find();
    }

    async findById(id: string): Promise<User | null> {
        return this.ormRepository.findOne({ where: { id } });
    }

    async findByEmail(email: string): Promise<User | null> {
        return this.ormRepository.findOne({ where: { email } });
    }

    async existsByEmail(email: string): Promise<boolean> {
        const count = await this.ormRepository.count({ where: { email } });
        return count > 0;
    }

    async update(id: string, updateUserDto: UpdateUserDto): Promise<User> {
        await this.ormRepository.update(id, updateUserDto);
        const user = await this.findById(id);
        if (!user) {
            throw new Error(`User with ID ${id} not found after update`);
        }
        return user;
    }

    async delete(id: string): Promise<void> {
        await this.ormRepository.delete(id);
    }
}
