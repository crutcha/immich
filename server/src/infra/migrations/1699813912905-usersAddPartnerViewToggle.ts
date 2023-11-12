import { MigrationInterface, QueryRunner } from "typeorm";

export class UsersAddPartnerViewToggle1699813912905 implements MigrationInterface {
    name = 'UsersAddPartnerViewToggle1699813912905'

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "users" ADD "partnerViewEnabled" boolean NOT NULL DEFAULT false`);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "partnerViewEnabled"`);
    }

}
