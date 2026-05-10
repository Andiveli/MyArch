import { ApiProperty } from '@nestjs/swagger';
import {
    IsEmail,
    IsNotEmpty,
    IsString,
    MinLength,
    Matches,
} from 'class-validator';

export class CreateUserDto {
    @ApiProperty({
        example: 'user@example.com',
        description: 'User email address',
    })
    @IsEmail()
    @IsNotEmpty()
    email: string;

    @ApiProperty({
        example: 'Password123',
        description:
            'User password (min 8 chars, uppercase, lowercase, number)',
    })
    @IsString()
    @MinLength(8)
    @Matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/, {
        message: 'Password must contain uppercase, lowercase and number',
    })
    password: string;

    @ApiProperty({
        example: 'John Doe',
        description: 'User full name',
    })
    @IsString()
    @MinLength(2)
    name: string;
}
