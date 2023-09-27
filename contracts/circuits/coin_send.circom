pragma circom 2.0.0;

include "hasher.circom";
include "utils.circom";
include "babyjub.circom";

template CSwap() {
    signal input a;
    signal input b;
    signal input swap;
    signal output l;
    signal output r;
    l <== (b - a) * swap + a;
    r <== (a - b) * swap + b;
}

template CoinWithdraw() {
    signal input index;
    signal input secret;
    signal input timestamp;
    signal input proof[32];
    signal input token;
    signal input amount;
    signal output root;
    signal output nullifier;

    signal commit;
    signal inters[33];

    component bd = BitDecompose(32);
    bd.num <== index;
    
    component pk = BabyPbk();
    pk.in <== secret;
    component commiter = Hasher();
    commiter.left <== pk.Ax;
    commiter.right <== pk.Ay;
    commit <== commiter.hash;

    component leaf_hasher = Hasher();
    leaf_hasher.left <== commit;
    leaf_hasher.right <== timestamp;
    inters[0] <== leaf_hasher.hash;

    component nullifier_hasher = Hasher();
    nullifier_hasher.left <== secret;
    nullifier_hasher.right <== index;
    nullifier <== nullifier_hasher.hash;

    component hashers[32];
    component swaps[32];
    for(var i=0; i < 32; i++) {
        swaps[i] = CSwap();
        swaps[i].swap <== bd.bits[i];
        swaps[i].a <== inters[i];
        swaps[i].b <== proof[i];

        hashers[i] = Hasher();
        hashers[i].left <== swaps[i].l;
        hashers[i].right <== swaps[i].r;
        inters[i+1] <== hashers[i].hash;
    }
    
    root <== inters[32];
 }

 component main {public [token, amount]}  = CoinWithdraw();