import { ApiProperty } from '@nestjs/swagger';

export class UserResponseDto {
    @ApiProperty({
        description: 'Success message',
        example: 'User created successfully',
        required: false,
    })
    message?: string;

    @ApiProperty({
        description: 'User data',
        example: {
            id: 'uuid',
            email: 'user@example.com',
            name: 'John Doe',
            createdAt: '2023-01-01T00:00:00.000Z',
        },
    })
    data: any; // Replace 'any' with User entity type
}
