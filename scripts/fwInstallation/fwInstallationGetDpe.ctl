void main(string dpe, string fn) {
    string val;
    dpGet(dpe, val);
    file f = fopen(fn,"w");
    fputs(val, f);
    fclose(f);
    
        
}
