import { ApiProperty } from '@nestjs/swagger';
import {
    IsEmail,
    IsString,
    MinLength,
    Matches,
    IsOptional,
} from 'class-validator';

export class UpdateUserDto {
    @ApiProperty({
        example: 'user@example.com',
        description: 'User email address',
        required: false,
    })
    @IsEmail()
    @IsOptional()
    email?: string;

    @ApiProperty({
        example: 'Password123',
        description:
            'User password (min 8 chars, uppercase, lowercase, number)',
        required: false,
    })
    @IsString()
    @MinLength(8)
    @Matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/, {
        message: 'Password must contain uppercase, lowercase and number',
    })
    @IsOptional()
    password?: string;

    @ApiProperty({
        example: 'John Doe',
        description: 'User full name',
        required: false,
    })
    @IsString()
    @MinLength(2)
    @IsOptional()
    name?: string;
}
