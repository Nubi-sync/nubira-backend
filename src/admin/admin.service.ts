import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ProductionOrder, POStatus } from './entities/production-order.entity';
import { Bundle, BundleStatus } from '../lineman/entities/bundle.entity';
import { UsersService } from '../users/users.service';
import { UserRole } from '../users/entities/user.entity';
import { Article } from './articles/entities/article.entity';
import { AuditService } from '../audit/audit.service';
import { DataSource } from 'typeorm';
import { Line } from './lines/entities/line.entity';

@Injectable()
export class AdminService {
  constructor(
    @InjectRepository(ProductionOrder)
    private readonly poRepository: Repository<ProductionOrder>,
    @InjectRepository(Bundle)
    private readonly bundleRepository: Repository<Bundle>,
    @InjectRepository(Article)
    private readonly articleRepository: Repository<Article>,
    @InjectRepository(Line)
    private readonly lineRepository: Repository<Line>,
    private readonly usersService: UsersService,
    private readonly auditService: AuditService,
    private readonly dataSource: DataSource,
  ) {}

  async createProductionOrder(dto: any, adminUser: any) {
    const { articleName, quantity, assignedLinemanId, pieceRate } = dto;
    
    const lineman = await this.usersService.findById(assignedLinemanId);
    if (!lineman || lineman.role !== UserRole.LINEMAN) {
      throw new BadRequestException('Invalid Lineman ID');
    }

    return this.dataSource.transaction(async (manager) => {
      const po = manager.create(ProductionOrder, {
        article_no: articleName,
        total_quantity: quantity,
        piece_rate: pieceRate,
        assignedLineman: lineman,
        status: POStatus.NEW,
      });

      const savedPo = await manager.save(po);

      const bundleSize = 50;
      const numBundles = Math.ceil(quantity / bundleSize);
      
      const bundles = [];
      for (let i = 0; i < numBundles; i++) {
        const bQty = (i === numBundles - 1 && quantity % bundleSize !== 0) 
            ? quantity % bundleSize 
            : bundleSize;
            
        const bNo = `B-${savedPo.id.split('-')[0].toUpperCase()}-${i+1}`;
        bundles.push(manager.create(Bundle, {
          bundle_no: bNo,
          barcode: bNo, // Barcode equals bundle_no for simplicity
          productionOrder: savedPo,
          quantity: bQty,
          status: BundleStatus.IN_STORE, // Starts at in_store
        }));
      }
      
      await manager.save(bundles);

      await this.auditService.logAction(
        'PO_CREATED',
        adminUser,
        'ProductionOrder',
        savedPo.id,
        { articleName, quantity, assignedLinemanId },
        manager
      );

      return {
        message: 'Production Order created and bundles generated successfully',
        data: savedPo
      };
    });
  }

  async getDashboardStats() {
    const totalProductionResult = await this.bundleRepository.createQueryBuilder('bundle')
      .select('SUM(bundle.quantity)', 'total')
      .getRawOne();
      
    const totalProduction = totalProductionResult.total ? parseInt(totalProductionResult.total) : 0;
      
    const activeLines = await this.lineRepository.count({ where: { isActive: true } });

    const qcRejectionsResult = await this.bundleRepository.createQueryBuilder('bundle')
      .select('SUM(bundle.rejected_quantity)', 'total')
      .getRawOne();
      
    const qcRejections = qcRejectionsResult.total ? parseInt(qcRejectionsResult.total) : 0;
    
    const pipeline = await this.bundleRepository.find({
      relations: {
        productionOrder: {
          assignedLineman: true
        }
      },
      take: 10,
      order: { created_at: 'DESC' }
    });

    const formattedPipeline = pipeline.map(b => ({
      bundleNo: b.bundle_no,
      article: b.productionOrder?.article_no,
      quantity: b.quantity,
      currentStage: b.status,
      assignedTo: b.productionOrder?.assignedLineman?.name,
    }));

    return {
      totalProduction,
      activeLines, 
      qcRejections,
      pipeline: formattedPipeline
    };
  }

  async getMasterData() {
    const linemen = await this.usersService.findAllByRole(UserRole.LINEMAN);
    const articles = await this.articleRepository.find();
    
    return {
      linemen: linemen.map(l => ({ id: l.id, name: l.name })),
      articles: articles.map(a => ({ id: a.id, name: a.name, rate: a.defaultPieceRate })),
    };
  }
}
