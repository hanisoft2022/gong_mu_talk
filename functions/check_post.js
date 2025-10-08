const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkSpecificPost() {
  const postsSnapshot = await db.collection('posts')
    .where('title', '==', '댓글 테스트용 글')
    .get();
  
  if (postsSnapshot.empty) {
    console.log('Post not found');
    process.exit(1);
  }
  
  const post = postsSnapshot.docs[0];
  const postId = post.id;
  const postData = post.data();
  
  console.log('Post ID:', postId);
  console.log('Stored commentCount:', postData.commentCount);
  
  const allComments = await db
    .collection('posts')
    .doc(postId)
    .collection('comments')
    .orderBy('createdAt')
    .get();
  
  console.log('\nAll comments:');
  allComments.docs.forEach((doc, idx) => {
    const data = doc.data();
    console.log(`${idx + 1}. ID: ${doc.id}`);
    console.log(`   Text: ${data.text?.substring(0, 50)}`);
    console.log(`   Deleted: ${data.deleted}`);
    console.log(`   Parent: ${data.parentCommentId || 'none'}`);
    console.log('');
  });
  
  const nonDeleted = allComments.docs.filter(doc => doc.data().deleted === false);
  console.log(`Total comments: ${allComments.docs.length}`);
  console.log(`Non-deleted: ${nonDeleted.length}`);
  console.log(`Stored: ${postData.commentCount}`);
  
  if (nonDeleted.length !== postData.commentCount) {
    console.log('\n❌ MISMATCH DETECTED!');
    console.log(`Updating: ${postData.commentCount} → ${nonDeleted.length}`);
    await post.ref.update({ commentCount: nonDeleted.length });
    console.log('✅ Fixed!');
  } else {
    console.log('\n✅ Counts match correctly');
  }
  
  process.exit(0);
}

checkSpecificPost().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
