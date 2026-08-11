import { Injectable, OnModuleInit } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User, UserRole } from './entities/user.entity';
import * as bcrypt from 'bcrypt';

@Injectable()
export class UsersService implements OnModuleInit {
  constructor(
    @InjectRepository(User)
    private usersRepository: Repository<User>,
  ) {}

  async onModuleInit() {
    const adminExists = await this.findByUsername('admin');
    if (!adminExists) {
      await this.create({
        username: 'admin',
        password: 'password', // will be hashed in create()
        name: 'Super Admin',
        role: UserRole.ADMIN,
      });
      console.log('✅ Default Admin user created: admin / password');
    }
  }

  async findByUsername(username: string): Promise<User | null> {
    return this.usersRepository.findOne({ where: { username } });
  }

  async create(userData: Partial<User>): Promise<User> {
    const newUser = this.usersRepository.create(userData);
    if (userData.password) {
      const salt = await bcrypt.genSalt();
      newUser.password = await bcrypt.hash(userData.password, salt);
    }
    return this.usersRepository.save(newUser);
  }

  async findById(id: string): Promise<User | null> {
    return this.usersRepository.findOne({ where: { id } });
  }

  async findAllByRole(role: UserRole): Promise<User[]> {
    return this.usersRepository.find({ where: { role } });
  }
}
