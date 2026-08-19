import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

export enum UserRole {
  ADMIN = 'ADMIN',
  LINEMAN = 'LINEMAN',
  STORE = 'STORE',
  PRODUCTION = 'PRODUCTION',
  DISPATCH = 'DISPATCH',
}

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  username: string;

  @Column({ select: false })
  password?: string; // Storing hashed password

  @Column()
  name: string;

  @Column({
    type: 'enum',
    enum: UserRole,
    default: UserRole.LINEMAN,
  })
  role: UserRole;

  @Column({ nullable: true })
  line_no: string; // Only for Lineman role

  @CreateDateColumn()
  created_at: Date;

  @UpdateDateColumn()
  updated_at: Date;
}
