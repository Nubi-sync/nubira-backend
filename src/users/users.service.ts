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
    try {
      const adminExists = await this.findByUsername('admin');
      if (!adminExists) {
        await this.create({
          username: 'admin',
          password: 'password',
          name: 'Super Admin',
          role: UserRole.ADMIN,
        });
        console.log('✅ Default Admin user initialized');
      }
    } catch (e) {
      console.log('User service startup check:', (e as any)?.message || 'ready');
    }
  }

  async findByUsername(username: string): Promise<User | null> {
    return this.usersRepository.createQueryBuilder('user')
      .where('user.username = :username', { username })
      .addSelect('user.password')
      .getOne();
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

  async findAll(): Promise<User[]> {
    return this.usersRepository.find({
      order: { created_at: 'DESC' },
    });
  }

  async update(id: string, updateData: Partial<User>): Promise<User> {
    const user = await this.findById(id);
    if (!user) {
      throw new Error('User not found');
    }

    if (updateData.password) {
      const salt = await bcrypt.genSalt();
      updateData.password = await bcrypt.hash(updateData.password, salt);
    }

    Object.assign(user, updateData);
    return this.usersRepository.save(user);
  }
}
