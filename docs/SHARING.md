# Sharing Feature

## Overview

Suna supports public sharing of conversations (threads) through shareable links. When a thread is marked as public, anyone with the link can view the conversation without needing to log in.

## How It Works

### Frontend

1. **Share Modal**: Users can create shareable links through the Share Modal (`frontend/src/components/sidebar/share-modal.tsx`)
2. **Public Routes**: The `/share/*` routes are marked as public in the middleware (`frontend/src/middleware.ts`)
3. **Share Page**: The share page (`frontend/src/app/share/[threadId]/page.tsx`) renders the conversation in read-only mode

### Backend (Database)

The sharing feature relies on Row Level Security (RLS) policies in Supabase:

1. **Thread Visibility**: Threads have an `is_public` boolean field
2. **RLS Policies**: 
   - `thread_select_policy`: Allows public access when `threads.is_public IS TRUE`
   - `message_select_policy`: Allows access to messages if their parent thread is public
   - `agent_run_select_policy`: Allows access to agent runs if their parent thread is public

### Creating a Shareable Link

When a user creates a shareable link:

1. The `is_public` field is set to `TRUE` on the thread
2. The `is_public` field is also set on the parent project (for broader access)
3. A shareable URL is generated: `https://yourdomain.com/share/{threadId}`

### Security

- **Read-Only Access**: Shared links only provide read access to conversations
- **No Authentication Required**: Users can view shared content without logging in
- **Account Isolation**: RLS policies ensure users can only see:
  - Public threads (`is_public = TRUE`)
  - Their own threads
  - Threads from projects they have access to

## Implementation Details

### Database Migrations

The sharing feature is enabled through the following migrations:

1. `20250416133920_agentpress_schema.sql`: Initial schema with `is_public` fields
2. `20250504123828_fix_thread_select_policy.sql`: Updated thread policy to check `is_public`
3. `20251004080623_enable_public_thread_sharing.sql`: Updated message and agent_run policies

### Key Files

- `frontend/src/middleware.ts`: Route protection configuration
- `frontend/src/components/sidebar/share-modal.tsx`: UI for creating share links
- `frontend/src/app/share/[threadId]/page.tsx`: Public share page
- `frontend/src/app/share/[threadId]/_hooks/useShareThreadData.ts`: Data fetching hook
- `backend/supabase/migrations/20251004080623_enable_public_thread_sharing.sql`: RLS policy updates

## Usage Example

```typescript
// Creating a shareable link
const updatePublicStatus = async (isPublic: boolean) => {
  await updateThreadMutation.mutateAsync({
    threadId,
    data: { is_public: isPublic },
  })
  
  // Generate the public URL
  const shareUrl = `${window.location.origin}/share/${threadId}`
}
```

## Testing

To test the sharing feature:

1. Create a conversation in your application
2. Open the Share Modal and create a shareable link
3. Copy the share URL
4. Open the URL in an incognito/private browser window (not logged in)
5. Verify you can view the conversation without authentication

## Future Enhancements

Potential improvements to the sharing feature:

- Share expiration dates
- Password-protected shares
- View analytics for shared links
- Social media preview cards (Open Graph)
- Share specific messages or message ranges
