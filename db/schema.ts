import { integer, sqliteTable, text } from 'drizzle-orm/sqlite-core';
// A personal workspace is saved atomically so reorders and cross-day moves cannot partially apply.
export const workspaces = sqliteTable('planner_workspaces', {
 ownerId: text('owner_id').primaryKey(),
 state: text('state').notNull(),
 revision: integer('revision').notNull().default(0),
 updatedAt: text('updated_at').notNull(),
});
