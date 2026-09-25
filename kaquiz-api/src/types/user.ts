export interface UpdateUserInput {
    avatar?: string;
    name?: string;
}

export interface UserResponse {
    id: number;
    name: string;
    avatar: string | null;
    email: string;
}