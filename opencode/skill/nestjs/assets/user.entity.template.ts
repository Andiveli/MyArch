import {
    Entity,
    Column,
    PrimaryGeneratedColumn,
    CreateDateColumn,
    UpdateDateColumn,
} from 'typeorm';
import { ApiProperty } from '@nestjs/swagger';

@Entity('users')
export class User {
    @ApiProperty({
        example: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
        description: 'User unique identifier',
    })
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @ApiProperty({
        example: 'user@example.com',
        description: 'User email address',
    })
    @Column({ unique: true })
    email: string;

    @ApiProperty({
        example: 'John Doe',
        description: 'User full name',
    })
    @Column()
    name: string;

    @ApiProperty({
        example: '$2b$10$exampleHashedPassword',
        description: 'Hashed password',
    })
    @Column()
    password: string;

    @ApiProperty({
        example: '2023-01-01T00:00:00.000Z',
        description: 'User creation timestamp',
    })
    @CreateDateColumn()
    createdAt: Date;

    @ApiProperty({
        example: '2023-01-01T00:00:00.000Z',
        description: 'User last update timestamp',
    })
    @UpdateDateColumn()
    updatedAt: Date;
}
